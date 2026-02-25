import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/signalr_service.dart';

class DamageMeterProvider extends ChangeNotifier {
  DamageMeterData _data = DamageMeterData();
  StreamSubscription? _sub;

  DamageMeterData get data => _data;
  List<DamageMeterFragment> get fragments => _data.fragments;

  void listen(SignalRService service) {
    _sub?.cancel();
    _sub = service.damageMeterStream.listen((data) {
      _data = data;
      notifyListeners();
    });
  }

  void clear() {
    _data = DamageMeterData();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
