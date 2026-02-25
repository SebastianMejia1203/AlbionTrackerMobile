import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/signalr_service.dart';

class PartyProvider extends ChangeNotifier {
  PartyData? _data;
  StreamSubscription? _sub;

  PartyData? get data => _data;
  List<PartyPlayerData> get players => _data?.players ?? [];
  int get playerCount => _data?.players.length ?? 0;
  double get averageIp => _data?.averagePartyIp ?? 0;

  void listen(SignalRService service) {
    _sub?.cancel();
    _sub = service.partyStream.listen((data) {
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
