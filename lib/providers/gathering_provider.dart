import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/signalr_service.dart';

/// Resource categories for filtering
enum GatheringResourceFilter {
  all,
  wood,
  hide,
  ore,
  rock,
  fiber,
  fish,
}

class GatheringProvider extends ChangeNotifier {
  GatheringListData _data = GatheringListData();
  StreamSubscription? _sub;
  StreamSubscription? _statusSub;

  // Filter state
  GatheringResourceFilter _resourceFilter = GatheringResourceFilter.all;
  String _mapFilter = ''; // empty = all maps
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _isTrackingActive = true;

  GatheringListData get data => _data;
  List<GatheredData> get allItems => _data.gatheredItems;
  GatheringStatsData get serverStats => _data.stats;
  bool get isTrackingActive => _isTrackingActive;

  GatheringResourceFilter get resourceFilter => _resourceFilter;
  String get mapFilter => _mapFilter;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;

  /// Locally-computed stats from items — always accurate
  GatheringStatsData get stats => _computeStats(allItems);

  static String classifyResource(GatheredData item) {
    final un = item.uniqueName.toUpperCase();
    if (item.hasBeenFished || un.contains('FISH')) return 'fish';
    if (un.contains('WOOD') || un.contains('PLANKS')) return 'wood';
    if (un.contains('HIDE') || un.contains('LEATHER')) return 'hide';
    if (un.contains('ORE') || un.contains('METALBAR')) return 'ore';
    if (un.contains('ROCK') || un.contains('STONEBLOCK')) return 'rock';
    if (un.contains('FIBER') || un.contains('CLOTH')) return 'fiber';
    return 'other';
  }

  GatheringStatsData _computeStats(List<GatheredData> items) {
    int totalProcesses = 0, totalRes = 0;
    int silverWood = 0, silverHide = 0, silverOre = 0;
    int silverRock = 0, silverFiber = 0, silverFish = 0;
    int cWood = 0, cHide = 0, cOre = 0, cRock = 0, cFiber = 0, cFish = 0;
    int totalSilver = 0;

    for (final item in items) {
      totalProcesses += item.miningProcesses;
      totalRes += item.gainedTotalAmount;
      totalSilver += item.totalMarketValue;
      final type = classifyResource(item);
      switch (type) {
        case 'wood':
          cWood += item.gainedTotalAmount;
          silverWood += item.totalMarketValue;
          break;
        case 'hide':
          cHide += item.gainedTotalAmount;
          silverHide += item.totalMarketValue;
          break;
        case 'ore':
          cOre += item.gainedTotalAmount;
          silverOre += item.totalMarketValue;
          break;
        case 'rock':
          cRock += item.gainedTotalAmount;
          silverRock += item.totalMarketValue;
          break;
        case 'fiber':
          cFiber += item.gainedTotalAmount;
          silverFiber += item.totalMarketValue;
          break;
        case 'fish':
          cFish += item.gainedTotalAmount;
          silverFish += item.totalMarketValue;
          break;
      }
    }

    return GatheringStatsData(
      totalMiningProcesses: totalProcesses,
      totalResources: totalRes,
      totalGainedSilver: totalSilver,
      gainedSilverByWood: silverWood,
      gainedSilverByHide: silverHide,
      gainedSilverByOre: silverOre,
      gainedSilverByRock: silverRock,
      gainedSilverByFiber: silverFiber,
      gainedSilverByFish: silverFish,
      woodCount: cWood,
      hideCount: cHide,
      oreCount: cOre,
      rockCount: cRock,
      fiberCount: cFiber,
      fishCount: cFish,
    );
  }

  /// Returns items after applying all filters
  List<GatheredData> get filteredItems {
    var items = allItems;

    // Resource filter
    if (_resourceFilter != GatheringResourceFilter.all) {
      items = items.where((i) => _matchesResourceFilter(i)).toList();
    }

    // Map filter
    if (_mapFilter.isNotEmpty) {
      items = items.where((i) =>
        i.clusterIndex == _mapFilter || i.mapDisplayName == _mapFilter
      ).toList();
    }

    // Date filter
    if (_dateFrom != null || _dateTo != null) {
      items = items.where((i) {
        if (i.timestampUtc.isEmpty) return true;
        try {
          final dt = DateTime.parse(i.timestampUtc);
          if (_dateFrom != null && dt.isBefore(_dateFrom!)) return false;
          if (_dateTo != null && dt.isAfter(_dateTo!.add(const Duration(days: 1)))) return false;
          return true;
        } catch (_) {
          return true;
        }
      }).toList();
    }

    return items;
  }

  /// Unique map names from all items (for map filter dropdown)
  List<String> get availableMaps {
    final maps = <String>{};
    for (final item in allItems) {
      final name = item.mapDisplayName.isNotEmpty
          ? item.mapDisplayName
          : item.clusterIndex;
      if (name.isNotEmpty) maps.add(name);
    }
    return maps.toList()..sort();
  }

  bool _matchesResourceFilter(GatheredData item) {
    final un = item.uniqueName.toUpperCase();
    switch (_resourceFilter) {
      case GatheringResourceFilter.wood:
        return un.contains('WOOD') || un.contains('PLANKS');
      case GatheringResourceFilter.hide:
        return un.contains('HIDE') || un.contains('LEATHER');
      case GatheringResourceFilter.ore:
        return un.contains('ORE') || un.contains('METALBAR');
      case GatheringResourceFilter.rock:
        return un.contains('ROCK') || un.contains('STONEBLOCK');
      case GatheringResourceFilter.fiber:
        return un.contains('FIBER') || un.contains('CLOTH');
      case GatheringResourceFilter.fish:
        return item.hasBeenFished || un.contains('FISH');
      case GatheringResourceFilter.all:
        return true;
    }
  }

  void setResourceFilter(GatheringResourceFilter filter) {
    _resourceFilter = filter;
    notifyListeners();
  }

  void setMapFilter(String map) {
    _mapFilter = map;
    notifyListeners();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    _dateFrom = from;
    _dateTo = to;
    notifyListeners();
  }

  void clearFilters() {
    _resourceFilter = GatheringResourceFilter.all;
    _mapFilter = '';
    _dateFrom = null;
    _dateTo = null;
    notifyListeners();
  }

  /// Remove items locally by guids
  void removeItemsLocally(List<String> guids) {
    _data = GatheringListData(
      gatheredItems: _data.gatheredItems.where((i) => !guids.contains(i.guid)).toList(),
      stats: _data.stats,
    );
    notifyListeners();
  }

  void clear() {
    _data = GatheringListData();
    notifyListeners();
  }

  void listen(SignalRService service) {
    _sub?.cancel();
    _sub = service.gatheringStream.listen((data) {
      _data = data;
      notifyListeners();
    });
    _statusSub?.cancel();
    _statusSub = service.gatheringStatusStream.listen((active) {
      _isTrackingActive = active;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }
}
