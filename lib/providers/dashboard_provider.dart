import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/signalr_service.dart';

class DashboardDataPoint {
  final DateTime time;
  final double fame;
  final double silver;
  final double reSpec;

  DashboardDataPoint({
    required this.time,
    required this.fame,
    required this.silver,
    required this.reSpec,
  });
}

class DashboardProvider extends ChangeNotifier {
  DashboardData _data = DashboardData();
  StreamSubscription? _sub;

  // History for charts — record a point whenever values actually change, keep up to 500 points
  final List<DashboardDataPoint> _history = [];
  static const int _maxHistory = 500;

  // Track last recorded values to detect actual changes
  double _lastFame = -1;
  double _lastSilver = -1;
  double _lastReSpec = -1;

  DashboardData get data => _data;
  List<DashboardDataPoint> get history => _history;

  void listen(SignalRService service) {
    _sub?.cancel();
    _sub = service.dashboardStream.listen((data) {
      _data = data;

      final now = DateTime.now();
      final fame = data.totalGainedFameInSession;
      final silver = data.totalGainedSilverInSession;
      final reSpec = data.totalGainedReSpecPointsInSession;

      // Always record the very first point
      if (_history.isEmpty) {
        _lastFame = fame;
        _lastSilver = silver;
        _lastReSpec = reSpec;
        _history.add(DashboardDataPoint(time: now, fame: fame, silver: silver, reSpec: reSpec));
      } else {
        // Only add a new point when at least one value has actually changed
        if (fame != _lastFame || silver != _lastSilver || reSpec != _lastReSpec) {
          // Insert a "hold" point at the current time with OLD values
          // so the step-line stays flat until the change moment
          _history.add(DashboardDataPoint(
            time: now.subtract(const Duration(milliseconds: 100)),
            fame: _lastFame,
            silver: _lastSilver,
            reSpec: _lastReSpec,
          ));
          // Then insert the new values at the current time
          _history.add(DashboardDataPoint(time: now, fame: fame, silver: silver, reSpec: reSpec));
          _lastFame = fame;
          _lastSilver = silver;
          _lastReSpec = reSpec;
        } else {
          // Values haven't changed — just update the "trailing edge" timestamp
          // so the chart extends to show current time even without changes.
          // Replace last point if it had the same values (extend the flat line).
          final last = _history.last;
          if (last.fame == fame && last.silver == silver && last.reSpec == reSpec) {
            _history[_history.length - 1] = DashboardDataPoint(
              time: now,
              fame: fame,
              silver: silver,
              reSpec: reSpec,
            );
          }
        }

        // Trim excess
        while (_history.length > _maxHistory) {
          _history.removeAt(0);
        }
      }

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
