import 'dart:async';
import 'dart:math';

class SimulatedPrediction {
  final String plantId;
  final String timestamp;
  final String severity;
  final double anomalyScore;
  final double confidence;
  final double stability;
  final double rollingAvg;
  final double rollingStd;
  final List<SimulatedTopCause> topCauses;
  final String rootCause;
  final String recommendation;
  final bool bufferFilled;
  final int bufferLen;

  SimulatedPrediction({
    required this.plantId,
    required this.timestamp,
    required this.severity,
    required this.anomalyScore,
    required this.confidence,
    required this.stability,
    required this.rollingAvg,
    required this.rollingStd,
    required this.topCauses,
    required this.rootCause,
    required this.recommendation,
    required this.bufferFilled,
    required this.bufferLen,
  });
}

class SimulatedTopCause {
  final String sensor;
  final double impact;

  SimulatedTopCause({required this.sensor, required this.impact});
}

class AlertItem {
  final String id;
  final String title;
  final String description;
  final String machine;
  final String time;
  final DateTime timestamp;
  final String severity;
  final String rootCause;
  final String rootCauseDetail;
  final String action;
  final List<String> additionalActions;
  final String eventLog;
  final Map<String, dynamic> rawData;
  bool acknowledged;

  AlertItem({
    required this.id,
    required this.title,
    required this.description,
    required this.machine,
    required this.time,
    required this.timestamp,
    required this.severity,
    required this.rootCause,
    required this.rootCauseDetail,
    required this.action,
    required this.additionalActions,
    required this.eventLog,
    required this.rawData,
    this.acknowledged = false,
  });
}

class SimulatedAIService {
  static final SimulatedAIService _instance = SimulatedAIService._internal();
  factory SimulatedAIService() => _instance;
  SimulatedAIService._internal();

  final _predictionController =
      StreamController<SimulatedPrediction>.broadcast();
  Stream<SimulatedPrediction> get predictionStream =>
      _predictionController.stream;

  final _alertController = StreamController<List<AlertItem>>.broadcast();
  Stream<List<AlertItem>> get alertStream => _alertController.stream;

  final List<AlertItem> _alerts = [];
  Timer? _timer;
  final Random _random = Random();

  double _currentAnomalyScore = 0.15;
  int _bufferCount = 120;
  int _cycleTick = 0;
  final int _anomalyThreshold = 600; // Anomaly every 10 minutes

  void startSimulation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _generatePrediction();
    });
  }

  void stopSimulation() {
    _timer?.cancel();
  }

  void _generatePrediction() {
    _cycleTick++;

    // Anomaly every ~45 seconds (persists for 5 seconds)
    bool isAnomaly =
        (_cycleTick % _anomalyThreshold) >= (_anomalyThreshold - 5);

    if (isAnomaly) {
      // Randomly choose between Medium, High, and Critical
      double type = _random.nextDouble();
      if (type < 0.3) {
        _currentAnomalyScore =
            0.45 + _random.nextDouble() * 0.15; // Medium (0.45-0.60)
      } else if (type < 0.7) {
        _currentAnomalyScore =
            0.65 + _random.nextDouble() * 0.15; // High (0.65-0.80)
      } else {
        _currentAnomalyScore =
            0.85 + _random.nextDouble() * 0.14; // Critical (0.85-0.99)
      }
    } else {
      _currentAnomalyScore = 0.05 + _random.nextDouble() * 0.15;
    }
    _currentAnomalyScore = _currentAnomalyScore.clamp(0.0, 1.0);

    String severity = 'normal';
    if (_currentAnomalyScore > 0.8) {
      severity = 'critical';
    } else if (_currentAnomalyScore > 0.6) {
      severity = 'high';
    } else if (_currentAnomalyScore > 0.4) {
      severity = 'medium';
    }

    _bufferCount = (_bufferCount + 1) % 500;

    final prediction = SimulatedPrediction(
      plantId: 'CARBON_EDGE_PLANT_01',
      timestamp: _formatTime(DateTime.now()),
      severity: severity,
      anomalyScore: _currentAnomalyScore,
      confidence: isAnomaly
          ? 92.0 + _random.nextDouble() * 5
          : 85.0 + _random.nextDouble() * 10,
      stability: isAnomaly
          ? 65.0 + _random.nextDouble() * 15
          : 92.0 + _random.nextDouble() * 5,
      rollingAvg: _currentAnomalyScore * 0.8 + 0.05,
      rollingStd: 0.02 + _random.nextDouble() * 0.05,
      topCauses: isAnomaly
          ? [
              SimulatedTopCause(sensor: 'Exhaust Temp', impact: 0.75),
              SimulatedTopCause(sensor: 'Fuel Intake', impact: 0.50),
              SimulatedTopCause(sensor: 'Turbine Speed', impact: 0.35),
            ]
          : [],
      rootCause: isAnomaly
          ? 'Thermal breach in primary exhaust manifold'
          : 'Normal Operating Conditions',
      recommendation: isAnomaly
          ? 'Initiate emergency cooling and inspect exhaust gaskets'
          : 'Continue standard monitoring protocol',
      bufferFilled: true,
      bufferLen: _bufferCount,
    );

    _predictionController.add(prediction);

    if (severity == 'critical' || severity == 'high') {
      _createAlert(prediction);
    }
  }

  void _createAlert(SimulatedPrediction prediction) {
    final now = DateTime.now();
    final alert = AlertItem(
      id: now.millisecondsSinceEpoch.toString(),
      title: 'AI Anomaly Detected - ${prediction.plantId}',
      description: 'Pattern deviation detected in heat suppression system',
      machine: 'MAIN TURBINE A1',
      time: _formatTime(now),
      timestamp: now,
      severity:
          prediction.severity[0].toUpperCase() +
          prediction.severity.substring(1),
      rootCause: prediction.rootCause,
      rootCauseDetail:
          'The AI model identified high correlation between Exhaust Temperature and Fuel Intake pressure, indicating a potential leak or blockage.',
      action: prediction.recommendation,
      additionalActions: [
        'Review sensor trends for the past 2 hours',
        'Verify coolant pressure levels',
        'Deploy technician to Zone 4',
      ],
      eventLog:
          'Auto-generated alert by CarbonEdge AI\nAnomaly Score: ${prediction.anomalyScore.toStringAsFixed(3)}\nConfidence: ${prediction.confidence.toStringAsFixed(1)}%',
      rawData: {
        'anomaly_score': prediction.anomalyScore,
        'confidence': prediction.confidence,
        'stability': prediction.stability,
        'top_causes': prediction.topCauses
            .map((c) => {'sensor': c.sensor, 'impact': c.impact})
            .toList(),
      },
    );

    _alerts.insert(0, alert);
    if (_alerts.length > 50) _alerts.removeLast();
    _alertController.add(List.from(_alerts));
  }

  void acknowledgeAlert(String id) {
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index != -1) {
      _alerts[index].acknowledged = true;
      _alertController.add(List.from(_alerts));
    }
  }

  void deleteAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    _alertController.add(List.from(_alerts));
  }

  void clearAlerts() {
    _alerts.clear();
    _alertController.add(List.from(_alerts));
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}:"
        "${dateTime.second.toString().padLeft(2, '0')}";
  }
}
