import 'package:flutter/material.dart';

/// Maps known stat types to their asset icon files.
/// Falls back to a Material icon if the asset doesn't exist.
class GameIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const GameIcon({super.key, required this.name, this.size = 20, this.color});

  static const _iconMap = {
    'fame': 'assets/icons/fame.png',
    'silver': 'assets/icons/silver.png',
    'respec': 'assets/icons/respec.png',
    'might': 'assets/icons/might.png',
    'favor': 'assets/icons/favor.png',
    'dungeon': 'assets/icons/dungeon.png',
    'zone': 'assets/icons/zone.png',
    'crown': 'assets/icons/crown.png',
    'book': 'assets/icons/book.png',
    'heart': 'assets/icons/heart.png',
    'skull': 'assets/icons/skull.png',
    'boss': 'assets/icons/boss.png',
    'gold': 'assets/icons/gold.png',
    'shields': 'assets/icons/shields.png',
    'satchel': 'assets/icons/satchel.png',
  };

  @override
  Widget build(BuildContext context) {
    final path = _iconMap[name];
    if (path != null) {
      return Image.asset(
        path,
        width: size,
        height: size,
        color: color,
        colorBlendMode: color != null ? BlendMode.srcIn : null,
        errorBuilder: (_, __, ___) => Icon(Icons.help_outline, size: size, color: color),
      );
    }
    return Icon(Icons.help_outline, size: size, color: color);
  }
}
