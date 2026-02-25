import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ItemImageWidget extends StatelessWidget {
  final String uniqueName;
  final int quality;
  final double size;
  final int enchantment;

  const ItemImageWidget({
    super.key,
    required this.uniqueName,
    this.quality = 0,
    this.size = 48,
    this.enchantment = 0,
  });

  String get _imageUrl {
    if (uniqueName.isEmpty) return '';
    String name = uniqueName;
    if (enchantment > 0) {
      name = '$name@$enchantment';
    }
    return 'https://render.albiononline.com/v1/item/$name.png?quality=$quality&size=${size.toInt() * 2}';
  }

  Color get _qualityBorderColor {
    switch (quality) {
      case 1: return Colors.white;
      case 2: return Colors.green;
      case 3: return Colors.blue;
      case 4: return Colors.purple;
      case 5: return Colors.orange;
      default: return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uniqueName.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.help_outline, size: size * 0.5, color: Colors.grey[600]),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: quality > 0
            ? Border.all(color: _qualityBorderColor, width: 2)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(quality > 0 ? 6 : 8),
        child: CachedNetworkImage(
          imageUrl: _imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[800],
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[800],
            child: Icon(
              Icons.broken_image,
              size: size * 0.4,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}
