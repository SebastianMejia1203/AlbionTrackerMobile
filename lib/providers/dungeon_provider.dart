import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/signalr_service.dart';

class DungeonProvider extends ChangeNotifier {
  DungeonListData _data = DungeonListData();
  StreamSubscription? _sub;

  DungeonListData get data => _data;
  List<DungeonFragment> get dungeons => _data.dungeons;
  DungeonStats get stats => _data.stats;

  /// Remove a dungeon locally by hash (optimistic removal before server confirms)
  void removeDungeonLocally(String hash) {
    _data = DungeonListData(
      dungeons: _data.dungeons.where((d) => d.dungeonHash != hash).toList(),
      stats: _data.stats,
    );
    notifyListeners();
  }

  void clear() {
    _data = DungeonListData();
    notifyListeners();
  }

  void listen(SignalRService service) {
    _sub?.cancel();
    _sub = service.dungeonsStream.listen((data) {
      _data = data;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
