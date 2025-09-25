import 'package:flutter/material.dart';

// Login Background (Naranja-Gris + Azul)
class LoginBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Forma principal naranja-gris
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
        const Color(0xFFFF8C42), // Naranja
        const Color(0xFF4A5568), // Gris
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(path, paint);
    
    // Forma azul lateral derecha
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
        const Color(0xFF63B3ED), // Azul claro
        const Color(0xFF4299E1), // Azul
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(bluePath, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Register Background (Gris-Azul)
class RegisterBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Forma principal gris-azul
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
        const Color(0xFF4A5568), // Gris
        const Color(0xFF4299E1), // Azul
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(path, paint);
    
    // Forma azul inferior
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
        const Color(0xFF63B3ED), // Azul claro
        const Color(0xFF4299E1), // Azul
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(secondaryPath, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}