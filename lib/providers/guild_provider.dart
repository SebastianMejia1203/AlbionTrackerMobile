import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/signalr_service.dart';

class GuildProvider extends ChangeNotifier {
  GuildData? _data;
  StreamSubscription? _sub;

  GuildData? get data => _data;
  List<SiphonedEnergyItem> get siphonedEnergy => _data?.siphonedEnergyList ?? [];
  List<SiphonedEnergyOverview> get siphonedOverview => _data?.siphonedEnergyOverview ?? [];
  int get totalSiphonedQuantity => _data?.totalSiphonedEnergyQuantity ?? 0;

  void listen(SignalRService service) {
    _sub?.cancel();
    _sub = service.guildStream.listen((data) {
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
