import 'package:flutter/material.dart';

import 'notifications_modal.dart';

/// Custom clipper for the organic curved header bottom edge.
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    
    // First curve
    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 15);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    // Second curve
    final secondControlPoint = Offset(size.width * 0.75, size.height - 35);
    final secondEndPoint = Offset(size.width, size.height - 15);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// A softer organic curved clipper for the top app banner headers.
class SoftCurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 36);

    final controlPoint1 = Offset(size.width * 0.35, size.height);
    final endPoint1 = Offset(size.width * 0.65, size.height - 20);
    path.quadraticBezierTo(
      controlPoint1.dx,
      controlPoint1.dy,
      endPoint1.dx,
      endPoint1.dy,
    );

    final controlPoint2 = Offset(size.width * 0.88, size.height - 40);
    final endPoint2 = Offset(size.width, size.height - 10);
    path.quadraticBezierTo(
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint2.dx,
      endPoint2.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// FoodLink Logo Row with Leaf and Notification / Settings Action
class FoodLinkHeaderTopRow extends StatelessWidget {
  final Widget? trailing;
  final VoidCallback? onTrailingTap;
  final bool hasNotificationDot;

  const FoodLinkHeaderTopRow({
    super.key,
    this.trailing,
    this.onTrailingTap,
    this.hasNotificationDot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Brand Logo
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'FoodLink',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),

        // Trailing icon (Notification bell or Settings)
        if (trailing != null)
          trailing!
        else
          InkWell(
            onTap: onTrailingTap ?? () => NotificationsModal.show(context),
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                if (hasNotificationDot)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Salad Bowl Illustration matching the "Donate Food" banner
class SaladBowlIllustration extends StatelessWidget {
  final double size;

  const SaladBowlIllustration({super.key, this.size = 90});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SaladBowlPainter(),
      ),
    );
  }
}

class _SaladBowlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Floating hearts
    final heartPaint = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.fill;

    _drawHeart(canvas, Offset(w * 0.3, h * 0.18), w * 0.09, heartPaint);
    _drawHeart(canvas, Offset(w * 0.72, h * 0.15), w * 0.08, heartPaint);
    _drawHeart(canvas, Offset(w * 0.88, h * 0.28), w * 0.065, heartPaint);

    // White Bowl
    final bowlPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final bowlShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Bowl rim & base path
    final bowlPath = Path();
    bowlPath.moveTo(w * 0.15, h * 0.52);
    bowlPath.quadraticBezierTo(w * 0.18, h * 0.88, w * 0.5, h * 0.90);
    bowlPath.quadraticBezierTo(w * 0.82, h * 0.88, w * 0.85, h * 0.52);
    bowlPath.close();

    canvas.drawPath(bowlPath, bowlPaint);

    // Inner rim shadow
    final rimRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.52),
      width: w * 0.7,
      height: h * 0.18,
    );
    canvas.drawOval(rimRect, bowlShadowPaint);

    // Green Salad / Veggies spilling out
    final greenPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;
    final darkGreenPaint = Paint()
      ..color = const Color(0xFF15803D)
      ..style = PaintingStyle.fill;
    final tomatoPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    final carrotPaint = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.fill;

    // Leaves
    canvas.drawCircle(Offset(w * 0.35, h * 0.44), w * 0.13, greenPaint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.40), w * 0.15, darkGreenPaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.45), w * 0.12, greenPaint);

    // Tomatoes
    canvas.drawCircle(Offset(w * 0.42, h * 0.46), w * 0.065, tomatoPaint);
    canvas.drawCircle(Offset(w * 0.60, h * 0.44), w * 0.06, tomatoPaint);

    // Carrots / Dressing
    canvas.drawCircle(Offset(w * 0.50, h * 0.48), w * 0.05, carrotPaint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size,
      center.dy - size * 0.6,
      center.dx - size * 0.5,
      center.dy - size,
      center.dx,
      center.dy - size * 0.4,
    );
    path.cubicTo(
      center.dx + size * 0.5,
      center.dy - size,
      center.dx + size,
      center.dy - size * 0.6,
      center.dx,
      center.dy + size * 0.3,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Veggie Box Illustration matching the "Welfare Centre Dashboard" banner
class VeggieBoxIllustration extends StatelessWidget {
  final double size;

  const VeggieBoxIllustration({super.key, this.size = 90});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _VeggieBoxPainter(),
      ),
    );
  }
}

class _VeggieBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Veggies behind crate
    final greenPaint = Paint()..color = const Color(0xFF22C55E);
    final darkGreenPaint = Paint()..color = const Color(0xFF15803D);
    final tomatoPaint = Paint()..color = const Color(0xFFEF4444);
    final carrotPaint = Paint()..color = const Color(0xFFF97316);

    // Leaf cluster
    canvas.drawCircle(Offset(w * 0.35, h * 0.42), w * 0.16, darkGreenPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.34), w * 0.18, greenPaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.40), w * 0.15, darkGreenPaint);

    // Carrots & Tomatoes sticking out
    canvas.drawCircle(Offset(w * 0.42, h * 0.40), w * 0.08, tomatoPaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.38), w * 0.075, carrotPaint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.44), w * 0.065, tomatoPaint);

    // Wooden / Cardboard Crate
    final cratePaint = Paint()..color = const Color(0xFFE5A663);
    final crateDarkPaint = Paint()..color = const Color(0xFFD0893F);

    // Crate base
    final crateRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.48, w * 0.76, h * 0.40),
      const Radius.circular(8),
    );
    canvas.drawRRect(crateRRect, cratePaint);

    // Slat lines
    final linePaint = Paint()
      ..color = crateDarkPaint.color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(w * 0.15, h * 0.68),
      Offset(w * 0.85, h * 0.68),
      linePaint,
    );
    canvas.drawLine(
      Offset(w * 0.38, h * 0.48),
      Offset(w * 0.38, h * 0.88),
      linePaint,
    );
    canvas.drawLine(
      Offset(w * 0.62, h * 0.48),
      Offset(w * 0.62, h * 0.88),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Community Volunteer Illustration Card at the bottom of Profile Screen
class GoodFoodCommunityCard extends StatelessWidget {
  const GoodFoodCommunityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF8F1), // Soft mint tint
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1FAE5), width: 1.2),
      ),
      child: Row(
        children: [
          // Graphic avatar / volunteer holding crate
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Leaf background
                Positioned(
                  bottom: 2,
                  child: Icon(
                    Icons.eco,
                    size: 32,
                    color: Colors.green.shade200,
                  ),
                ),
                const Icon(
                  Icons.volunteer_activism_rounded,
                  color: Color(0xFF15803D),
                  size: 38,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Slogan & Heart
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Good Food',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF14532D),
                    letterSpacing: -0.2,
                  ),
                ),
                Row(
                  children: const [
                    Text(
                      'Brighter Communities',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5B4DDF), // Royal purple
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.favorite,
                      size: 16,
                      color: Color(0xFFF97316), // Orange heart
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed Border Container for "Upload food image"
class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double height;
  final Color borderColor;

  const DashedBorderContainer({
    super.key,
    required this.child,
    required this.onTap,
    this.height = 100,
    this.borderColor = const Color(0xFF86EFAC),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _DashedRectPainter(color: borderColor),
        child: Container(
          width: double.infinity,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;

  _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      const Radius.circular(16),
    );

    final path = Path()..addRRect(rrect);
    final dashPath = _createDashedPath(path, 6.0, 4.0);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source, double dashLength, double dashSpace) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashLength < metric.length)
            ? dashLength
            : metric.length - distance;
        dest.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dashLength + dashSpace;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 3 Stat Badges Card Row (used in Profile & Welfare Dashboard)
class StatItemData {
  final String label;
  final String value;
  final Color bgColor;
  final Color textColor;
  final IconData? icon;

  const StatItemData({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.textColor,
    this.icon,
  });
}

class StatRow extends StatelessWidget {
  final List<StatItemData> items;

  const StatRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: item.bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (item.icon != null) ...[
                      Icon(item.icon, size: 18, color: item.textColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: item.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: item.textColor.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Status Pill Badge ("Pending", "Accepted", "Rejected")
class StatusPill extends StatelessWidget {
  final String status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status.isEmpty ? 'Pending' : status;

    switch (status.toLowerCase()) {
      case 'accepted':
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Accepted';
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = 'Rejected';
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFEF3C7); // Soft light amber
        fg = const Color(0xFFD97706); // Warm amber
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
