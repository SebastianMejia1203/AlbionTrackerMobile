import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/signalr_service.dart';

class LoggingProvider extends ChangeNotifier {
  List<LoggingNotification> _notifications = [];
  StreamSubscription? _bulkSub;
  StreamSubscription? _realtimeSub;

  // Filters
  final Set<String> _activeFilters = {
    'kill', 'fame', 'silver', 'equipmentloot', 'consumableloot',
    'simpleloot', 'unknownloot', 'faction', 'seasonpoints',
  };
  String _searchQuery = '';

  List<LoggingNotification> get notifications => _filteredNotifications;
  List<LoggingNotification> get allNotifications => _notifications;
  int get count => _filteredNotifications.length;
  int get totalCount => _notifications.length;
  Set<String> get activeFilters => _activeFilters;
  String get searchQuery => _searchQuery;

  List<LoggingNotification> get _filteredNotifications {
    var result = _notifications;

    // Apply type filter
    if (_activeFilters.length < 9) {
      result = result.where((n) {
        final type = _normalizeType(n.type);
        return _activeFilters.contains(type);
      }).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((n) {
        final frag = n.fragment;
        return frag.localizedName.toLowerCase().contains(q) ||
            frag.description.toLowerCase().contains(q) ||
            frag.lootedByName.toLowerCase().contains(q) ||
            frag.lootedFromName.toLowerCase().contains(q) ||
            frag.killedBy.toLowerCase().contains(q) ||
            frag.died.toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }

  String _normalizeType(String type) {
    final t = type.toLowerCase();
    // Group loot subtypes
    if (t.contains('loot') || t == 'othergrabbledloot' || t == 'othergrabbledlootnotification') {
      if (t.contains('equipment')) return 'equipmentloot';
      if (t.contains('consumable')) return 'consumableloot';
      if (t.contains('simple')) return 'simpleloot';
      return 'unknownloot';
    }
    if (t.contains('kill')) return 'kill';
    if (t.contains('fame')) return 'fame';
    if (t.contains('silver')) return 'silver';
    if (t.contains('faction')) return 'faction';
    if (t.contains('season')) return 'seasonpoints';
    return t;
  }

  void toggleFilter(String filter) {
    if (_activeFilters.contains(filter)) {
      _activeFilters.remove(filter);
    } else {
      _activeFilters.add(filter);
    }
    notifyListeners();
  }

  void setAllFilters(bool active) {
    if (active) {
      _activeFilters.addAll([
        'kill', 'fame', 'silver', 'equipmentloot', 'consumableloot',
        'simpleloot', 'unknownloot', 'faction', 'seasonpoints',
      ]);
    } else {
      _activeFilters.clear();
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clear() {
    _notifications.clear();
    notifyListeners();
  }

  void listen(SignalRService service) {

    _bulkSub = service.loggingListStream.listen((data) {
      _notifications = data;
      notifyListeners();
    });

    // Also listen to real-time individual notifications
    _realtimeSub = service.loggingStream.listen((notification) {
      _notifications.insert(0, notification);
      // Keep max 500 entries
      if (_notifications.length > 500) {
        _notifications = _notifications.sublist(0, 500);
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _bulkSub?.cancel();
    _realtimeSub?.cancel();
    super.dispose();
  }
}
