import 'package:intl/intl.dart';

class Formatters {
  static final _numberFormat = NumberFormat('#,##0');
  static final _decimalFormat = NumberFormat('#,##0.0');
  static final _percentFormat = NumberFormat('#,##0.0%');
  static final _silverFormat = NumberFormat('#,##0');
  static final _compactFormat = NumberFormat.compact();
  static final _dateFormat = DateFormat('dd/MM HH:mm');
  static final _timeFormat = DateFormat('HH:mm:ss');

  static String number(num value) => _numberFormat.format(value);

  static String decimal(num value) => _decimalFormat.format(value);

  static String percent(double value) => _percentFormat.format(value);

  static String silver(num value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(2)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return _silverFormat.format(value);
  }

  static String compact(num value) => _compactFormat.format(value);

  static String fame(num value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(2)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return _numberFormat.format(value);
  }

  static String duration(int totalSeconds) {
    if (totalSeconds <= 0) return '0s';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  static String durationFromMs(int ms) => duration(ms ~/ 1000);

  static String dateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoString);
      return _dateFormat.format(dt.toLocal());
    } catch (_) {
      return isoString;
    }
  }

  static String time(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoString);
      return _timeFormat.format(dt.toLocal());
    } catch (_) {
      return isoString;
    }
  }

  static String tierLabel(int tier) {
    if (tier <= 0) return '';
    return 'T$tier';
  }

  static String ipLabel(double itemPower) {
    return '${itemPower.toStringAsFixed(0)} IP';
  }
}
