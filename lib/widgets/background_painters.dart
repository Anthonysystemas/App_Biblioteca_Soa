import 'package:flutter/material.dart';

class LoginBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.4);
    path.quadraticBezierTo(
      size.width * 0.8, size.height * 0.5,
      size.width * 0.6, size.height * 0.45,
    );
    path.quadraticBezierTo(
      size.width * 0.3, size.height * 0.38,
      0, size.height * 0.5,
    );
    path.close();
    
    paint.shader = LinearGradient(
      colors: [
        const Color(0xFFFF8C42),
        const Color(0xFF4A5568),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(path, paint);
    
    final bluePath = Path();
    bluePath.moveTo(size.width, size.height * 0.3);
    bluePath.lineTo(size.width, size.height);
    bluePath.lineTo(size.width * 0.7, size.height);
    bluePath.quadraticBezierTo(
      size.width * 0.8, size.height * 0.8,
      size.width * 0.9, size.height * 0.6,
    );
    bluePath.close();
    
    paint.shader = LinearGradient(
      colors: [
        const Color(0xFF63B3ED),
        const Color(0xFF4299E1),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(bluePath, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RegisterBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.7, size.height * 0.7,
      size.width * 0.4, size.height * 0.65,
    );
    path.quadraticBezierTo(
      size.width * 0.2, size.height * 0.62,
      0, size.height * 0.7,
    );
    path.close();
    
    paint.shader = LinearGradient(
      colors: [
        const Color(0xFF0D47A1),
        const Color(0xFF1976D2),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(path, paint);
    
    final secondaryPath = Path();
    secondaryPath.moveTo(size.width * 0.3, size.height * 0.4);
    secondaryPath.lineTo(size.width, size.height * 0.2);
    secondaryPath.lineTo(size.width, size.height);
    secondaryPath.lineTo(0, size.height);
    secondaryPath.quadraticBezierTo(
      size.width * 0.2, size.height * 0.8,
      size.width * 0.3, size.height * 0.4,
    );
    secondaryPath.close();
    
    paint.shader = LinearGradient(
      colors: [
        const Color(0xFF2196F3),
        const Color(0xFF64B5F6),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(secondaryPath, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}