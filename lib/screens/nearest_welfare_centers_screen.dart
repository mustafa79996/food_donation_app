import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../utils/voice_input.dart';

class WelfareCenter {
  final String name;
  final String address;
  final String distance;
  final String phone;
  final double latitude;
  final double longitude;

  const WelfareCenter({
    required this.name,
    required this.address,
    required this.distance,
    required this.phone,
    required this.latitude,
    required this.longitude,
  });
}

class NearestWelfareCentersScreen extends StatefulWidget {
  const NearestWelfareCentersScreen({super.key, this.centersStream});

  final Stream<List<WelfareCenter>>? centersStream;

  @override
  State<NearestWelfareCentersScreen> createState() =>
      _NearestWelfareCentersScreenState();
}

class _NearestWelfareCentersScreenState
    extends State<NearestWelfareCentersScreen> {
  static const _localCenterRadiusKm = 25.0;

  Position? _currentPosition;
  bool _isLoading = true;
  String? _statusMessage;
  List<WelfareCenter> _firestoreCenters = const [];
  List<WelfareCenter> _liveNearbyCenters = const [];
  List<_CenterDisplay> _sortedCenters = const [];
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<List<WelfareCenter>>? _centersSubscription;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _detectedArea;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _listenToCenters();
    _loadCurrentLocationAndCentres();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _centersSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _listenToCenters() {
    if (widget.centersStream != null) {
      _centersSubscription = widget.centersStream!.listen(
        (centers) {
          if (!mounted) return;
          setState(() {
            _firestoreCenters = centers;
            _rebuildSortedCenters();
            _isLoading = false;
          });
        },
        onError: (_) {
          if (!mounted) return;
          setState(() {
            _firestoreCenters = const [];
            _rebuildSortedCenters();
            _isLoading = false;
          });
        },
      );
      return;
    }

    try {
      final stream = FirebaseFirestore.instance
          .collection('public_welfare_centres')
          .snapshots()
          .map((snapshot) {
            final centers = <WelfareCenter>[];
            for (final doc in snapshot.docs) {
              final data = doc.data();
              final lat = (data['latitude'] as num?)?.toDouble();
              final lon = (data['longitude'] as num?)?.toDouble();
              if (lat == null || lon == null) continue;
              centers.add(
                WelfareCenter(
                  name: data['name'] as String? ?? 'Welfare Centre',
                  address: data['address'] as String? ?? '',
                  distance: '',
                  phone: data['phone'] as String? ?? '',
                  latitude: lat,
                  longitude: lon,
                ),
              );
            }
            return centers;
          });

      _centersSubscription = stream.listen(
        (centers) {
          if (!mounted) return;
          setState(() {
            _firestoreCenters = centers;
            _rebuildSortedCenters();
          });
        },
        onError: (Object error) {
          debugPrint('Firestore public welfare centres note: $error');
          if (!mounted) return;
          setState(() {
            _firestoreCenters = const [];
            _rebuildSortedCenters();
          });
        },
      );
    } catch (e) {
      debugPrint('Firestore stream init note: $e');
    }
  }

  void _startLocationUpdates() {
    _positionSubscription?.cancel();
    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 15,
    );

    try {
      _positionSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings).listen(
            (position) {
              if (!mounted) return;
              setState(() {
                _currentPosition = position;
                _rebuildSortedCenters();
                _isLoading = false;
              });
              _maybeDetectArea(position);
            },
            onError: (_) {},
          );
    } catch (_) {}
  }

  Future<void> _loadCurrentLocationAndCentres() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _statusMessage =
              'Enable device location to show real centres near your current location.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _statusMessage =
              'Allow location access to show welfare centres near your current location.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 7),
        ),
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });

      _maybeDetectArea(position);

      // If no custom test stream was provided, fetch real nearby centres around current GPS
      if (widget.centersStream == null) {
        final realNearby = await _fetchRealCentresAroundPosition(
          position.latitude,
          position.longitude,
        );
        if (!mounted) return;
        setState(() {
          _liveNearbyCenters = realNearby;
          _rebuildSortedCenters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _rebuildSortedCenters();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _rebuildSortedCenters();
      });
    }
  }

  /// Searches for real welfare centres, orphanages, NGOs, and charity organisations
  /// around the user's current GPS coordinates using OpenStreetMap Nominatim.
  Future<List<WelfareCenter>> _fetchRealCentresAroundPosition(
    double lat,
    double lon,
  ) async {
    final list = <WelfareCenter>[];

    for (final keyword in ['welfare', 'orphanage', 'charity']) {
      try {
        final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
          'q': keyword,
          'format': 'json',
          'limit': '6',
          'viewbox': '${lon - 0.25},${lat + 0.25},${lon + 0.25},${lat - 0.25}',
        });

        final response = await http.get(
          uri,
          headers: {'User-Agent': 'FoodLinkApp/1.0 (contact@foodlink.org)'},
        ).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final items = jsonDecode(response.body) as List;
          for (final item in items) {
            final rawLat = item['lat'];
            final rawLon = item['lon'];
            if (rawLat == null || rawLon == null) continue;
            final pLat = double.tryParse(rawLat.toString());
            final pLon = double.tryParse(rawLon.toString());
            if (pLat == null || pLon == null) continue;

            final fullName = item['display_name'] as String? ?? 'Welfare Centre';
            final parts = fullName.split(',');
            final name = parts.isNotEmpty ? parts.first.trim() : 'Welfare Centre';
            final address = parts.length > 1
                ? parts.skip(1).take(3).join(',').trim()
                : fullName;

            final exists = list.any(
              (c) =>
                  c.name.toLowerCase() == name.toLowerCase() ||
                  (c.latitude == pLat && c.longitude == pLon),
            );

            if (!exists) {
              list.add(
                WelfareCenter(
                  name: name,
                  address: address,
                  distance: '',
                  phone: '',
                  latitude: pLat,
                  longitude: pLon,
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Nominatim query note: $e');
      }
    }

    return list;
  }

  void _rebuildSortedCenters() {
    // Combine real Firestore centres and live OpenStreetMap nearby centres
    final all = <WelfareCenter>[..._firestoreCenters];

    for (final live in _liveNearbyCenters) {
      final exists = all.any(
        (c) =>
            c.name.toLowerCase() == live.name.toLowerCase() ||
            (c.latitude == live.latitude && c.longitude == live.longitude),
      );
      if (!exists) {
        all.add(live);
      }
    }

    if (_currentPosition == null) {
      _sortedCenters = all
          .map(
            (c) => _CenterDisplay(
              center: c,
              distanceKm: double.infinity,
              isNearby: true,
            ),
          )
          .toList();
      return;
    }

    final displays = all.map((c) {
      final d = _calculateDistanceKm(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        c.latitude,
        c.longitude,
      );
      return _CenterDisplay(
        center: c,
        distanceKm: d,
        isNearby: d <= _localCenterRadiusKm,
      );
    }).toList();

    displays.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    _sortedCenters = displays;
  }

  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final lat1Rad = lat1 * (pi / 180);
    final lon1Rad = lon1 * (pi / 180);
    final lat2Rad = lat2 * (pi / 180);
    final lon2Rad = lon2 * (pi / 180);

    final deltaLat = lat2Rad - lat1Rad;
    final deltaLon = lon2Rad - lon1Rad;

    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  void _maybeDetectArea(Position position) {
    if (_detectedArea != null) return;
    unawaited(_detectArea(position));
  }

  Future<void> _detectArea(Position position) async {
    final result = await _reverseGeocode(position);
    if (!mounted || result == null) return;
    setState(() {
      _detectedArea = result;
    });
  }

  Future<String?> _reverseGeocode(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final label = _joinDistinct([
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ]);
        if (label.isNotEmpty) {
          return label;
        }
      }
    } catch (_) {}

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'json',
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'zoom': '16',
        'addressdetails': '1',
      });
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'FoodLink/1.0 (Flutter)',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data is Map && data['address'] is Map
            ? (data['address'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
        final parts = <String>[];
        for (final key in const [
          'suburb',
          'neighbourhood',
          'village',
          'town',
          'city',
          'state',
        ]) {
          final value = address[key];
          if (value is String &&
              value.trim().isNotEmpty &&
              !parts.contains(value)) {
            parts.add(value);
          }
        }
        if (parts.isNotEmpty) {
          return parts.take(2).join(', ');
        }
      }
    } catch (_) {}

    return null;
  }

  String _joinDistinct(Iterable<String?> values) {
    final seen = <String>{};
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) seen.add(trimmed);
    }
    return seen.join(', ');
  }

  Future<void> _callCenter(WelfareCenter center) async {
    if (center.phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: center.phone);

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open phone dialer');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to make call: $e')));
    }
  }

  Future<void> _openMaps(WelfareCenter center) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(center.name)}&center=${center.latitude},${center.longitude}',
    );
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open maps');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open Maps: $e')));
    }
  }

  Future<void> _openNearbyMapsSearch() async {
    final lat = _currentPosition?.latitude ?? 17.3850;
    final lon = _currentPosition?.longitude ?? 78.4867;

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('welfare centre or orphanage or charity')}&center=$lat,$lon',
    );
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open maps');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open Maps: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final centers = query.isEmpty
        ? _sortedCenters
        : _sortedCenters.where((display) {
            final center = display.center;
            return center.name.toLowerCase().contains(query) ||
                center.address.toLowerCase().contains(query) ||
                center.phone.contains(query);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearest Welfare Centers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Current Location & Centres',
            onPressed: _loadCurrentLocationAndCentres,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                labelText: 'Search welfare centers',
                hintText: 'Type or speak a centre name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: VoiceInputIconButton(
                  controller: _searchController,
                  tooltip: 'Search by voice',
                  onResult: (value) => setState(() => _searchQuery = value),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            if (_currentPosition != null) ...[
              Row(
                children: [
                  const Icon(
                    Icons.my_location,
                    size: 16,
                    color: Color(0xFF1E7D45),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _detectedArea == null
                          ? 'Current Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                          : 'Current Location: $_detectedArea',
                      style: const TextStyle(
                        color: Color(0xFF1E7D45),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (_statusMessage != null) ...[
              Text(
                _statusMessage!,
                style: const TextStyle(color: Colors.orange, fontSize: 13),
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 6),
            Expanded(
              child: _isLoading && centers.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Finding centres near your current location...'),
                        ],
                      ),
                    )
                  : centers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_city_outlined,
                              size: 64,
                              color: Colors.green.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              query.isNotEmpty
                                  ? 'No centres match "$_searchQuery"'
                                  : 'No welfare centres found near current location',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Search directly on Google Maps or apply to register your welfare centre in FoodLink.',
                              style: TextStyle(color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _openNearbyMapsSearch,
                              icon: const Icon(Icons.explore_outlined),
                              label: const Text('Search on Google Maps'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E7D45),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: centers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final display = centers[index];
                        final center = display.center;
                        return Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.business,
                                      color: Color(0xFF1E7D45),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        center.name,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (display.distanceKm.isFinite)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          display.distanceKm < 1.0
                                              ? 'Nearby (< 1 km)'
                                              : '${display.distanceKm.toStringAsFixed(1)} km',
                                          style: const TextStyle(
                                            color: Color(0xFF1E7D45),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(center.address)),
                                  ],
                                ),
                                if (center.phone.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        size: 16,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(center.phone)),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (center.phone.isNotEmpty) ...[
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _callCenter(center),
                                          icon: const Icon(Icons.call),
                                          label: const Text('Call'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _openMaps(center),
                                        icon: const Icon(Icons.map_outlined),
                                        label: const Text('View on Maps'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF1E7D45),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openNearbyMapsSearch,
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Explore all nearby welfare centres on Google Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterDisplay {
  const _CenterDisplay({
    required this.center,
    required this.distanceKm,
    required this.isNearby,
  });

  final WelfareCenter center;
  final double distanceKm;
  final bool isNearby;
}
