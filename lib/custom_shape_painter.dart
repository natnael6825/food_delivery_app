import 'package:flutter/material.dart';

class CustomShapePainter extends CustomPainter {
  final Color color;
  final double triangleHeightFactor;

  CustomShapePainter({required this.color, this.triangleHeightFactor = 0.3});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = Path();
    double rectangleHeight = size.height * (1 - triangleHeightFactor);

    // Draw the rectangle
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, rectangleHeight);
    path.lineTo(0, rectangleHeight);
    path.close();

    // Draw the inverted triangle
    path.moveTo(0, rectangleHeight);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, rectangleHeight);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
