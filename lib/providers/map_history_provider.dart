import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/signalr_service.dart';

class MapHistoryProvider extends ChangeNotifier {
  MapHistoryData _data = MapHistoryData();
  StreamSubscription? _sub;

  MapHistoryData get data => _data;
  List<MapHistoryEntry> get entries => _data.entries;

  void clear() {
    _data = MapHistoryData();
    notifyListeners();
  }

  void listen(SignalRService service) {
    _sub?.cancel();
    _sub = service.mapHistoryStream.listen((data) {
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
