import 'package:flutter/material.dart';

class CircleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const CircleItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double circleSize = (screenWidth * 0.16).clamp(56.0, 80.0);
    final double spacing = (screenWidth * 0.04).clamp(12.0, 20.0);
    final double iconSize = (circleSize * 0.32).clamp(18.0, 28.0);
    final double labelFontSize = (circleSize * 0.14).clamp(10.0, 12.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: circleSize,
        margin: EdgeInsets.only(right: spacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                margin: EdgeInsets.all(circleSize * 0.15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),
            SizedBox(height: circleSize * 0.12),
            
            SizedBox(
              width: circleSize,
              height: labelFontSize * 2.2,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF374151),
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}