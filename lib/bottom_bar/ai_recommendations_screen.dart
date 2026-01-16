import 'dart:async';
import 'dart:math';
import 'package:carbonedge/services/simulation_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

// ==================== THEME CONSTANTS ====================
class NeonTheme {
  static const Color background = Color(0xFF0B0F17);
  static const Color cardBackground = Color(0xFF1A1F2E);
  static const Color orange = Color(0xFFFF7A33);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color lime = Color(0xFF33FF88);
  static const Color red = Color(0xFFFF3333);
  static const Color textMain = Colors.white;
  static const Color textDim = Colors.white70;
}

// ==================== MODEL CLASS ====================
class AIPrediction {
  final String plantId;
  final String timestamp;
  final String severity;
  final double anomalyScore;
  final double confidence;
  final double stability;
  final double rollingAvg;
  final double rollingStd;
  final List<TopCause> topCauses;
  final String rootCause;
  final String recommendation;
  final bool bufferFilled;
  final int bufferLen;

  AIPrediction({
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

  factory AIPrediction.fromJson(Map<String, dynamic> json) {
    return AIPrediction(
      plantId: json['plant_id'] ?? '',
      timestamp: json['timestamp'] ?? '',
      severity: json['severity'] ?? 'normal',
      anomalyScore: (json['anomaly_score'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0).toDouble(),
      stability: (json['stability'] ?? 0).toDouble(),
      rollingAvg: (json['rolling_avg'] ?? 0).toDouble(),
      rollingStd: (json['rolling_std'] ?? 0).toDouble(),
      topCauses:
          (json['top_causes'] as List?)
              ?.map((c) => TopCause.fromJson(c))
              .toList() ??
          [],
      rootCause: json['root_cause'] ?? '',
      recommendation: json['recommendation'] ?? '',
      bufferFilled: json['buffer_filled'] ?? false,
      bufferLen: json['buffer_len'] ?? 0,
    );
  }
}

class TopCause {
  final String sensor;
  final double impact;

  TopCause({required this.sensor, required this.impact});

  factory TopCause.fromJson(Map<String, dynamic> json) {
    return TopCause(
      sensor: json['sensor'] ?? '',
      impact: (json['impact'] ?? 0).toDouble(),
    );
  }
}

// ==================== HARDCODED DATA SIMULATOR ====================
class HardcodedDataSimulator {
  final _controller = StreamController<AIPrediction>.broadcast();
  Timer? _timer;
  final Random _random = Random();

  // Severity stability - only change every 20 seconds
  String _currentSeverity = 'normal';

  Stream<AIPrediction> get stream => _controller.stream;

  void connect() {
    _currentSeverity = 'low';
    _timer?.cancel();

    // Emit data every 1 second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final prediction = _generatePrediction();
      _controller.add(prediction);
    });

    // Emit first prediction immediately
    _controller.add(_generatePrediction());
  }

  AIPrediction _generatePrediction() {
    final now = DateTime.now();
    final seconds = SimulationState.currentSeconds;

    // Anomaly appears at 60 seconds and lasts until 80 seconds (20 second duration)
    // Then resets back to normal
    final isAnomaly = seconds >= 60 && seconds < 80;

    // Severity stability logic reset (managed by global cycle)
    if (seconds == 0) {
      _currentSeverity = 'normal';
    }

    if (isAnomaly) {
      return _generateAnomalyPrediction(now);
    } else {
      return _generateNormalPrediction(now);
    }
  }

  AIPrediction _generateNormalPrediction(DateTime timestamp) {
    final anomalyScore = SimulationState.getAnomalyScore('normal', _random);
    final confidence = 88.0 + _random.nextDouble() * 4.0;
    final stability = 92.0 + _random.nextDouble() * 4.0;

    return AIPrediction(
      plantId: 'cement_kiln_01',
      timestamp: _formatTimestamp(timestamp),
      severity: 'normal',
      anomalyScore: anomalyScore,
      confidence: confidence,
      stability: stability,
      rollingAvg: 0.16 + _random.nextDouble() * 0.1,
      rollingStd: 0.025 + _random.nextDouble() * 0.01,
      topCauses: [
        TopCause(
          sensor: 'vibration_level',
          impact: 2.2 + _random.nextDouble() * 0.3,
        ),
        TopCause(
          sensor: 'kiln_pressure',
          impact: 1.9 + _random.nextDouble() * 0.2,
        ),
        TopCause(
          sensor: 'exhaust_co2',
          impact: 1.6 + _random.nextDouble() * 0.2,
        ),
      ],
      rootCause: 'System operating within normal parameters',
      recommendation: 'Continue monitoring - all systems nominal',
      bufferFilled: true,
      bufferLen: 50,
    );
  }

  AIPrediction _generateAnomalyPrediction(DateTime timestamp) {
    final targetSeverity = SimulationState.currentCycleSeverity;
    final anomalyScore = SimulationState.getAnomalyScore(
      targetSeverity,
      _random,
    );
    final confidence = 78.0 + _random.nextDouble() * 8.0;
    final stability = 65.0 + _random.nextDouble() * 8.0;

    // Stick to one severity for the duration of the anomaly
    if (_currentSeverity == 'normal') {
      _currentSeverity = targetSeverity;
    }

    return AIPrediction(
      plantId: 'cement_kiln_01',
      timestamp: _formatTimestamp(timestamp),
      severity: _currentSeverity,
      anomalyScore: anomalyScore,
      confidence: confidence,
      stability: stability,
      rollingAvg: 0.68 + _random.nextDouble() * 0.15,
      rollingStd: 0.12 + _random.nextDouble() * 0.08,
      topCauses: [
        TopCause(
          sensor: 'vibration_level',
          impact: 8.2 + _random.nextDouble() * 1.5,
        ),
        TopCause(
          sensor: 'temperature_zone_3',
          impact: 7.5 + _random.nextDouble() * 1.2,
        ),
        TopCause(
          sensor: 'kiln_pressure',
          impact: 6.8 + _random.nextDouble() * 1.0,
        ),
        TopCause(
          sensor: 'exhaust_co2',
          impact: 5.9 + _random.nextDouble() * 0.8,
        ),
        TopCause(sensor: 'feed_rate', impact: 4.5 + _random.nextDouble() * 0.7),
      ],
      rootCause: 'Abnormal vibration pattern detected in kiln rotation system',
      recommendation:
          'Immediate inspection of kiln bearings and drive system recommended. Reduce feed rate by 15% and monitor temperature zones.',
      bufferFilled: true,
      bufferLen: 50,
    );
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

// ==================== MAIN PAGE ====================
class AIOptimizationPage extends StatefulWidget {
  const AIOptimizationPage({super.key});

  @override
  State<AIOptimizationPage> createState() => _AIOptimizationPageState();
}

class _AIOptimizationPageState extends State<AIOptimizationPage> {
  late HardcodedDataSimulator _dataSimulator;
  StreamSubscription? _subscription;

  AIPrediction? _currentPrediction;
  String? _error;

  // Local history for the trend chart
  final List<FlSpot> _anomalyHistory = [];
  double _timeCounter = 0;

  @override
  void initState() {
    super.initState();
    _dataSimulator = HardcodedDataSimulator();

    // Subscribe FIRST to avoid missing events
    _subscription = _dataSimulator.stream.listen(
      (prediction) {
        if (mounted) {
          setState(() {
            _currentPrediction = prediction;
            _error = null;

            // Update history
            _timeCounter += 1;
            _anomalyHistory.add(FlSpot(_timeCounter, prediction.anomalyScore));
            if (_anomalyHistory.length > 50) {
              _anomalyHistory.removeAt(0);
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = error.toString();
          });
        }
      },
    );

    // Connect AFTER subscribing
    _dataSimulator.connect();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _dataSimulator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: NeonTheme.background, body: _buildBody());
  }

  Widget _buildBody() {
    if (_error != null) {
      return _buildErrorState(_error!);
    }

    if (_currentPrediction == null) {
      return _buildLoadingState();
    }

    return _buildDashboard(_currentPrediction!);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: NeonTheme.orange),
          const SizedBox(height: 20),
          Text(
            'Connecting to AI System...',
            // Use standard TextStyle to ensure visibility even if GoogleFonts fails
            style: const TextStyle(color: NeonTheme.textDim, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: NeonTheme.red, size: 64),
            const SizedBox(height: 20),
            Text(
              'Connection Error',
              style: const TextStyle(
                color: NeonTheme.textMain,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: const TextStyle(color: NeonTheme.textDim, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _currentPrediction = null;
                });
                _dataSimulator.connect();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: NeonTheme.cyan,
                foregroundColor: Colors.black,
              ),
              child: const Text("Retry Connection"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(AIPrediction prediction) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1200;

        if (!isWide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAIColumn(prediction),
                const SizedBox(height: 16),
                _buildSensorImpactPanel(prediction),
                const SizedBox(height: 16),
                _buildAnomalyTrendPanel(),
                const SizedBox(height: 16),
                _buildSystemHealthPanel(prediction),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header Row: Plant Info (Left) | Buffer (Right)
              _buildHeader(prediction),
              const SizedBox(height: 24),
              // Row 1: AI Diagnostics (Left) | System Health (Right)
              Expanded(
                flex: 1,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 1, child: _buildAIColumn(prediction)),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _buildSystemHealthPanel(prediction),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Row 2: Anomaly Trend (Left) | Sensor Impact (Right) - Equal Height
              Expanded(
                flex: 1,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 1, child: _buildAnomalyTrendPanel()),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _buildSensorImpactPanel(prediction),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== PANELS ====================

  Widget _buildAIColumn(AIPrediction prediction) {
    return NeonPanel(
      title: 'AI DIAGNOSTICS',
      icon: Icons.psychology,
      color: NeonTheme.orange,
      expand: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow("ROOT CAUSE", prediction.rootCause, NeonTheme.red),
          const SizedBox(height: 20),
          _buildDetailRow(
            "RECOMMENDATION",
            prediction.recommendation,
            NeonTheme.lime,
          ),
        ],
      ),
    );
  }

  Widget _buildSensorImpactPanel(AIPrediction prediction) {
    final isNormal =
        prediction.severity.isEmpty ||
        ['normal', 'low'].contains(prediction.severity.toLowerCase());

    return NeonPanel(
      title: 'SENSOR IMPACT ANALYSIS',
      icon: Icons.bar_chart,
      color: NeonTheme.lime,
      child: isNormal
          ? Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: NeonTheme.lime.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: NeonTheme.lime),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: NeonTheme.lime,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "SYSTEM STATUS NORMAL",
                        style: GoogleFonts.inter(
                          color: NeonTheme.lime,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: SingleChildScrollView(
                child: SensorImpactBars(
                  causes: prediction.topCauses,
                  isNormal: isNormal,
                ),
              ),
            ),
    );
  }

  Widget _buildAnomalyTrendPanel() {
    return NeonPanel(
      title: 'ANOMALY SCORE TREND',
      icon: Icons.show_chart,
      color: NeonTheme.cyan,
      child: NeonLineChart(spots: _anomalyHistory),
    );
  }

  Widget _buildSystemHealthPanel(AIPrediction prediction) {
    return NeonPanel(
      title: 'SYSTEM HEALTH',
      icon: Icons.health_and_safety,
      color: NeonTheme.lime,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SeverityGauge(severity: prediction.severity),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: GlowingMetricCard(
                    label: "CONFIDENCE",
                    value: "${prediction.confidence.toStringAsFixed(1)}%",
                    icon: Icons.verified_user,
                    color: NeonTheme.cyan,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GlowingMetricCard(
                    label: "STABILITY",
                    value: "${prediction.stability.toStringAsFixed(1)}%",
                    icon: Icons.balance,
                    color: NeonTheme.lime,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GlowingMetricCard(
                    label: "ROLLING AVG",
                    value: prediction.rollingAvg.toStringAsFixed(3),
                    icon: Icons.trending_up,
                    color: NeonTheme.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== WIDGET HELPERS ====================

  Widget _buildHeader(AIPrediction prediction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const LivePulse(),
                const SizedBox(width: 12),
                Text(
                  "LIVE MONITORING",
                  style: GoogleFonts.inter(
                    color: NeonTheme.lime,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              prediction.plantId.toUpperCase(),
              style: GoogleFonts.inter(
                color: NeonTheme.textMain,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              prediction.timestamp,
              style: GoogleFonts.inter(color: NeonTheme.textDim, fontSize: 14),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: NeonTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: NeonTheme.cyan.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.memory, color: NeonTheme.cyan, size: 18),
              const SizedBox(width: 8),
              Text(
                "BUFFER: ${prediction.bufferLen}",
                style: GoogleFonts.inter(
                  color: NeonTheme.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            color: NeonTheme.textMain,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ==================== CUSTOM WIDGETS ====================

class NeonPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  final bool expand;

  const NeonPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NeonTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          if (expand)
            Expanded(
              child: Padding(padding: const EdgeInsets.all(20.0), child: child),
            )
          else
            Padding(padding: const EdgeInsets.all(20.0), child: child),
        ],
      ),
    );
  }
}

class LivePulse extends StatefulWidget {
  const LivePulse({super.key});

  @override
  State<LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<LivePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: NeonTheme.lime.withOpacity(_animation.value),
            boxShadow: [
              BoxShadow(
                color: NeonTheme.lime.withOpacity(_animation.value * 0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

class NeonLineChart extends StatelessWidget {
  final List<FlSpot> spots;

  const NeonLineChart({super.key, required this.spots});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [5, 5]),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 10,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.inter(
                    color: NeonTheme.textDim,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    color: NeonTheme.textDim,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
            isCurved: true,
            color: NeonTheme.cyan,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  NeonTheme.cyan.withOpacity(0.3),
                  NeonTheme.cyan.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minY: 0,
        maxY: 1.0, // Y-axis range 0-1.0
      ),
    );
  }
}

class SensorImpactBars extends StatelessWidget {
  final List<TopCause> causes;
  final bool isNormal;

  const SensorImpactBars({
    super.key,
    required this.causes,
    this.isNormal = false,
  });

  Color _getBarColor(double impact) {
    if (isNormal) return NeonTheme.cyan; // Or Green
    if (impact >= 7) return NeonTheme.red;
    if (impact >= 4) return NeonTheme.orange;
    return NeonTheme.lime;
  }

  @override
  Widget build(BuildContext context) {
    final displayCauses = isNormal
        ? [
            TopCause(sensor: 'VIBRATION LEVEL', impact: 10.0),
            TopCause(sensor: 'KILN PRESSURE', impact: 10.0),
            TopCause(sensor: 'EXHAUST CO2', impact: 10.0),
          ]
        : causes;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: displayCauses.map((cause) {
        final color = _getBarColor(cause.impact);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cause.sensor.toUpperCase().replaceAll('_', ' '),
                    style: GoogleFonts.inter(
                      color: NeonTheme.textDim,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isNormal) // Only show value if not normal (since normal is always 100%)
                    Text(
                      cause.impact.toStringAsFixed(2),
                      style: GoogleFonts.inter(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (cause.impact / 10.0).clamp(0.0, 1.0),
                  backgroundColor: Colors.white10,
                  color: color,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class SeverityGauge extends StatelessWidget {
  final String severity;
  final double radius;
  final double lineWidth;

  const SeverityGauge({
    super.key,
    required this.severity,
    this.radius = 110.0,
    this.lineWidth = 20.0,
  });

  Color _getColor() {
    switch (severity.toLowerCase()) {
      case 'critical':
        return NeonTheme.red;
      case 'high':
        return NeonTheme.orange;
      case 'warning':
        return Colors.yellow;
      case 'normal':
      case 'low':
      case '': // Handle empty string as normal
        return NeonTheme
            .cyan; // Or NeonTheme.green if available, but cyan fits the theme
      default:
        return NeonTheme.lime;
    }
  }

  double _getPercent() {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 1.0;
      case 'high':
        return 0.75;
      case 'warning':
        return 0.5;
      case 'normal':
      case 'low':
      case '': // Handle empty string as normal
        return 0.1; // Low percentage for normal
      default:
        return 0.25;
    }
  }

  String _getDisplayText() {
    if (severity.isEmpty || severity.toLowerCase() == 'normal') {
      return "NORMAL";
    }
    return severity.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return CircularPercentIndicator(
      radius: radius,
      lineWidth: lineWidth,
      percent: _getPercent(),
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "SEVERITY",
            style: GoogleFonts.inter(
              color: NeonTheme.textDim,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getDisplayText(),
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
      progressColor: color,
      backgroundColor: Colors.white10,
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
    );
  }
}

class GlowingMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const GlowingMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: NeonTheme.textDim,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//Sohan Merged
