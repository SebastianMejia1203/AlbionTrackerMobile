import 'package:flutter/material.dart';

/// Albion Online zone colors matching in-game appearance.
/// SafeArea = Blue zone, Yellow = Yellow zone, Red = Red zone, Black = Black zone.
class ZoneUtils {
  static Color clusterModeColor(String mode, {bool isDark = true}) {
    switch (mode) {
      case 'SafeArea':
        return isDark ? const Color(0xFF2196F3) : const Color(0xFF1565C0); // Blue zone
      case 'Yellow':
        return isDark ? const Color(0xFFFFCA28) : const Color(0xFFE6A800); // Yellow zone (darker for light bg)
      case 'Red':
        return isDark ? const Color(0xFFE53935) : const Color(0xFFC62828); // Red zone
      case 'Black':
        return isDark ? const Color(0xFF757575) : const Color(0xFF424242); // Black zone
      case 'AvalonTunnel':
        return isDark ? const Color(0xFF00BFA5) : const Color(0xFF00897B); // Avalon roads teal
      case 'Mists':
        return isDark ? const Color(0xFF7E57C2) : const Color(0xFF5E35B1); // Mists purple
      case 'Island':
        return isDark ? const Color(0xFF66BB6A) : const Color(0xFF388E3C); // Island green
      default:
        return isDark ? Colors.grey : Colors.grey[700]!;
    }
  }

  /// Lighter text color for dark zone backgrounds (Black zone).
  static Color clusterModeTextColor(String mode) {
    if (mode == 'Black') return const Color(0xFFBDBDBD);
    return clusterModeColor(mode);
  }

  static String clusterModeLabel(String mode) {
    switch (mode) {
      case 'SafeArea':
        return 'Zona Azul';
      case 'Yellow':
        return 'Zona Amarilla';
      case 'Red':
        return 'Zona Roja';
      case 'Black':
        return 'Zona Negra';
      case 'AvalonTunnel':
        return 'Caminos de Avalon';
      case 'Mists':
        return 'Nieblas';
      case 'Island':
        return 'Isla';
      case 'Hideout':
        return 'Hideout';
      default:
        return mode;
    }
  }

  /// Returns a lethality label for the zone mode.
  /// Blue/Yellow = No Letal, Red/Orange = Semi-Letal, Black = Letal
  static String lethalityLabel(String mode) {
    switch (mode) {
      case 'SafeArea':
      case 'Yellow':
      case 'Island':
        return 'No Letal';
      case 'Red':
        return 'Semi-Letal';
      case 'Black':
        return 'Zona Letal';
      case 'AvalonTunnel':
        return 'Letal (Avalon)';
      case 'Mists':
        return 'Letal (Nieblas)';
      case 'Hideout':
        return 'Seguro';
      default:
        return '';
    }
  }

  /// Color for lethality label
  static Color lethalityColor(String mode) {
    switch (mode) {
      case 'SafeArea':
      case 'Yellow':
      case 'Island':
      case 'Hideout':
        return const Color(0xFF66BB6A);
      case 'Red':
        return const Color(0xFFFF9800);
      case 'Black':
      case 'AvalonTunnel':
      case 'Mists':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  /// Human-readable label for WorldJsonType raw values.
  static String worldJsonTypeLabel(String worldJsonType) {
    if (worldJsonType.isEmpty) return '';
    final upper = worldJsonType.toUpperCase();
    if (upper.contains('SAFEAREA') || upper == 'HIDEOUT') return 'Zona Segura';
    if (upper == 'OPENPVP_YELLOW') return 'PvP Abierto - Amarilla';
    if (upper == 'OPENPVP_RED') return 'PvP Abierto - Roja';
    if (upper == 'OPENPVP_BLACK') return 'PvP Abierto - Negra';
    if (upper == 'MISTS') return 'Nieblas';
    if (upper.startsWith('TUNNEL_ROYAL')) return 'Túnel Real de Avalon';
    if (upper.startsWith('TUNNEL_BLACK_LOW')) return 'Túnel Negro (Bajo)';
    if (upper.startsWith('TUNNEL_BLACK_MEDIUM')) return 'Túnel Negro (Medio)';
    if (upper.startsWith('TUNNEL_BLACK_HIGH')) return 'Túnel Negro (Alto)';
    if (upper.startsWith('TUNNEL_LOW')) return 'Túnel de Avalon (Bajo)';
    if (upper.startsWith('TUNNEL_MEDIUM')) return 'Túnel de Avalon (Medio)';
    if (upper.startsWith('TUNNEL_HIGH')) return 'Túnel de Avalon (Alto)';
    if (upper.startsWith('TUNNEL_DEEP')) return 'Túnel Profundo de Avalon';
    if (upper.startsWith('TUNNEL_HIDEOUT')) return 'Hideout de Avalon';
    if (upper.contains('ISLAND')) return 'Isla';
    if (upper.contains('CORRUPTED')) return 'Mazmorra Corrupta';
    if (upper.contains('EXPEDITION')) return 'Expedición';
    if (upper.contains('RANDOMDUNGEON')) return 'Mazmorra Aleatoria';
    return worldJsonType; // fallback: show raw
  }

  /// Returns a region/city name for a mainClusterIndex when known.
  static String regionFromMainClusterIndex(String mainClusterIndex) {
    // Albion main city indices
    const cities = {
      '0301': 'Thetford',
      '1301': 'Fort Sterling',
      '2301': 'Lymhurst',
      '3301': 'Bridgewatch',
      '4301': 'Martlock',
      '3000': 'Caerleon',
      '3003': 'Caerleon',
      '0007': 'Brecilien',
      '3200': 'Carleon Slums',
      // Royal continent starting zones
      '0004': 'Thetford Portal',
      '1004': 'Fort Sterling Portal',
      '2004': 'Lymhurst Portal',
      '3004': 'Bridgewatch Portal',
      '4004': 'Martlock Portal',
    };
    return cities[mainClusterIndex] ?? '';
  }

  /// Human-readable label for MapType enum values.
  static String mapTypeLabel(String mapType) {
    switch (mapType) {
      case 'HellGate':
        return 'Puerta Infernal';
      case 'CorruptedDungeon':
        return 'Mazmorra Corrupta';
      case 'RandomDungeon':
        return 'Mazmorra Aleatoria';
      case 'Expedition':
        return 'Expedición';
      case 'Arena':
        return 'Arena';
      case 'Hideout':
        return 'Hideout';
      case 'Island':
        return 'Isla';
      case 'Mists':
        return 'Nieblas';
      case 'MistsDungeon':
        return 'Mazmorra de Nieblas';
      case 'Unknown':
        return 'Desconocido';
      default:
        return mapType;
    }
  }

  /// Human-readable label for MistsRarity.
  static String mistsRarityLabel(String rarity) {
    switch (rarity) {
      case 'Common':
        return 'Común';
      case 'Uncommon':
        return 'Poco Común';
      case 'Rare':
        return 'Raro';
      case 'Epic':
        return 'Épico';
      case 'Legendary':
        return 'Legendario';
      case 'Unknown':
      default:
        return '';
    }
  }

  /// Color for MistsRarity.
  static Color mistsRarityColor(String rarity) {
    switch (rarity) {
      case 'Common':
        return const Color(0xFF8D8D8D);
      case 'Uncommon':
        return const Color(0xFF4CAF50);
      case 'Rare':
        return const Color(0xFF2196F3);
      case 'Epic':
        return const Color(0xFF9C27B0);
      case 'Legendary':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }

  /// Icon for MapType.
  static IconData mapTypeIcon(String mapType) {
    switch (mapType) {
      case 'HellGate':
        return Icons.local_fire_department;
      case 'CorruptedDungeon':
        return Icons.flash_on;
      case 'RandomDungeon':
        return Icons.door_front_door;
      case 'Expedition':
        return Icons.explore;
      case 'Arena':
        return Icons.sports_kabaddi;
      case 'Hideout':
        return Icons.home;
      case 'Island':
        return Icons.landscape;
      case 'Mists':
        return Icons.cloud;
      case 'MistsDungeon':
        return Icons.cloud_circle;
      default:
        return Icons.map;
    }
  }
}
