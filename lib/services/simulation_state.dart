import 'package:flutter/foundation.dart';

class SimulationState {
  static final SimulationState _instance = SimulationState._internal();
  factory SimulationState() => _instance;
  SimulationState._internal();

  static bool isConnected = false;

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
