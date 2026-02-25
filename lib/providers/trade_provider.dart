import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/signalr_service.dart';

class TradeProvider extends ChangeNotifier {
  TradeListData _data = TradeListData();
  StreamSubscription? _sub;

  TradeListData get data => _data;
  List<TradeData> get trades => _data.trades;
  TradeStatsData get stats => _data.stats;

  void clear() {
    _data = TradeListData();
    notifyListeners();
  }

  void listen(SignalRService service) {
    _sub?.cancel();
    _sub = service.tradesStream.listen((data) {
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
