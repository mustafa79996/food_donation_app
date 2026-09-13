import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

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
  const NearestWelfareCentersScreen({super.key});

  @override
  State<NearestWelfareCentersScreen> createState() => _NearestWelfareCentersScreenState();
}

class _NearestWelfareCentersScreenState extends State<NearestWelfareCentersScreen> {
  static const _localCenterRadiusKm = 25.0;
  Position? _currentPosition;
  bool _isLoading = true;
  String? _statusMessage;
  List<_CenterDisplay> _sortedCenters = const [];
  StreamSubscription<Position>? _positionSubscription;

 static const List<WelfareCenter> _centers = [
  WelfareCenter(
  name: 'XYZ Orphanage',
  address: 'Nearby, Hyderabad',
  distance: '1.0 km',
  phone: '+919908849132',
  latitude: 17.4000,
  longitude: 78.4700,
),
  WelfareCenter(
    name: 'Hope Shelter',
    address: 'Nearby, Hyderabad',
    distance: '1.2 km',
    phone: '+916304870448',
    latitude: 17.3800,
    longitude: 78.4800,
  ),

  WelfareCenter(
    name: 'Bright Future Center',
    address: 'Nearby, Hyderabad',
    distance: '2.8 km',
    phone: '+918106211731',
    latitude: 17.3900,
    longitude: 78.4900,
  ),

  WelfareCenter(
    name: 'Community Care Hub',
    address: 'Nearby, Hyderabad',
    distance: '4.1 km',
    phone: '+15550103',
    latitude: 17.4000,
    longitude: 78.5000,
  ),
];

  @override
  void initState() {
    super.initState();
    _sortedCenters = _centers.map((center) => _CenterDisplay(center: center, distanceKm: double.infinity)).toList();
    _startLocationUpdates();
    _loadNearestCenters();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    _positionSubscription?.cancel();
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10,
    );

    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (position) {
        if (!mounted) return;
        setState(() {
          _currentPosition = position;
          _sortedCenters = _getSortedCenters(position);
          _isLoading = false;
          _statusMessage = null;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Live location updates are unavailable right now.';
        });
      },
    );
  }

  Future<void> _loadNearestCenters() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Please enable location services on your device to see the nearest centers.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Location permission was not granted. Please allow location access to see the nearest centers.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _sortedCenters = _getSortedCenters(position);
        _isLoading = false;
        _statusMessage = null;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Unable to read your location right now. Showing centers in default order.';
      });
    }
  }

  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final lat1Rad = lat1 * (pi / 180);
    final lon1Rad = lon1 * (pi / 180);
    final lat2Rad = lat2 * (pi / 180);
    final lon2Rad = lon2 * (pi / 180);

    final deltaLat = lat2Rad - lat1Rad;
    final deltaLon = lon2Rad - lon1Rad;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) + cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  List<_CenterDisplay> _getSortedCenters(Position? position) {
    if (position == null) {
      return _centers.map((center) => _CenterDisplay(center: center, distanceKm: double.infinity)).toList();
    }

    final list = _centers.map((center) {
      final distance = _calculateDistanceKm(
        position.latitude,
        position.longitude,
        center.latitude,
        center.longitude,
      );
      return _CenterDisplay(center: center, distanceKm: distance);
    }).where((display) => display.distanceKm <= _localCenterRadiusKm).toList();

    list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return list;
  }
Future<void> _callCenter(WelfareCenter center) async {
  final uri = Uri(
    scheme: 'tel',
    path: center.phone,
  );

  try {
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not open phone dialer');
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to make call: $e'),
      ),
    );
  }
}
  Future<void> _openMaps(WelfareCenter center) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(center.name)}&query_place_id=&center=${center.latitude},${center.longitude}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open maps');
    }
  }

  Future<void> _openNearbyMapsSearch() async {
    if (_currentPosition == null) {
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('welfare center')}&center=${_currentPosition!.latitude},${_currentPosition!.longitude}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open maps');
    }
  }

  @override
  Widget build(BuildContext context) {
    final centers = _sortedCenters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearest Welfare Centers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearestCenters,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nearest Welfare Centers',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _currentPosition != null
                  ? 'Live location is active. Centers are being ranked from your current position.'
                  : 'Using your current location to find the best drop-off center.',
              style: const TextStyle(color: Colors.black54),
            ),
            if (_currentPosition != null) ...[
              const SizedBox(height: 4),
              Text(
                'Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ],
            if (_statusMessage != null) ...[
              const SizedBox(height: 8),
              Text(_statusMessage!, style: const TextStyle(color: Colors.orange)),
            ],
            if (_currentPosition != null && centers.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'No verified centers are stored within 25 km of your location. Use Maps to find current nearby centers.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
            const SizedBox(height: 16),
            if (_currentPosition != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openNearbyMapsSearch,
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('Open nearby welfare centers in Maps'),
                ),
              ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.separated(
                  itemCount: centers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final display = centers[index];
                    final center = display.center;
                    return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_city_outlined, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(child: Text(center.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                              if (index == 0 && _currentPosition != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text('Nearest', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
                                )
                              else
                                Text(
                                  display.distanceKm.isFinite ? '${display.distanceKm.toStringAsFixed(1)} km' : center.distance,
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(center.address),
                          const SizedBox(height: 4),
                          Text(center.phone),
                          const SizedBox(height: 4),
                          Text(
                            display.distanceKm.isFinite ? 'About ${display.distanceKm.toStringAsFixed(1)} km away' : 'Distance unavailable',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          Row(
  children: [
    Expanded(
      child: OutlinedButton.icon(
        onPressed: () => _callCenter(center),
        icon: const Icon(Icons.call),
        label: const Text('Call'),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: OutlinedButton.icon(
        onPressed: () => _openMaps(center),
        icon: const Icon(Icons.map_outlined),
        label: const Text('Maps'),
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
          ],
        ),
      ),
    );
  }
}

class _CenterDisplay {
  const _CenterDisplay({required this.center, required this.distanceKm});

  final WelfareCenter center;
  final double distanceKm;
}
