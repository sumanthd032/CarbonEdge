import 'package:flutter/foundation.dart';
import 'dart:math';

class SimulationState {
  static final SimulationState _instance = SimulationState._internal();
  factory SimulationState() => _instance;
  SimulationState._internal();

  static bool isConnected = false;

  // Global simulation clock with random offset for synchronization
  static final int _randomOffset = Random().nextInt(80);
  static int get currentSeconds =>
      ((DateTime.now().millisecondsSinceEpoch / 1000).floor() + _randomOffset) %
      80;

  // Shared severity selection: different cycles have different target severities
  static String get currentCycleSeverity {
    final cycleIndex =
        ((DateTime.now().millisecondsSinceEpoch / 1000).floor() +
            _randomOffset) ~/
        80;
    final severities = ['high', 'warning', 'low'];
    return severities[cycleIndex % severities.length];
  }

  // Helper to get a score based on the target severity
  static double getAnomalyScore(String severity, Random random) {
    switch (severity) {
      case 'high':
        return 0.76 + random.nextDouble() * 0.22; // 0.76 - 0.98
      case 'warning':
        return 0.60 + random.nextDouble() * 0.15; // 0.60 - 0.75
      case 'low':
        return 0.40 + random.nextDouble() * 0.20; // 0.40 - 0.60
      default:
        return 0.15 + random.nextDouble() * 0.15; // 0.15 - 0.30 (Normal)
    }
  }

  // Use a ValueNotifier to allow widgets to reactively update if needed,
  // though for this specific task, a simple static flag + setState in Home is enough.
  static final ValueNotifier<bool> connectionNotifier = ValueNotifier<bool>(
    false,
  );

  static void setConnected(bool value) {
    isConnected = value;
    connectionNotifier.value = value;
  }
}
