import 'dart:async';
import 'dart:convert';
import 'package:carbonedge/services/simulation_state.dart';
import 'package:carbonedge/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Global configuration
class AlertConfig {
  static const String apiBaseUrl = 'http://192.168.240.91:8000';
  // For hackathon: anomaly must persist for 3 seconds
  static const Duration anomalyDuration = Duration(seconds: 3);
  static const Duration coolDownDuration = Duration(seconds: 12);
  static const Duration pollInterval = Duration(seconds: 1);
  static const int maxAlerts = 100;
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _selectedAlertIndex = 0;
  List<Map<String, dynamic>> _alerts = [];

  // API polling
  Timer? _pollTimer;
  bool _isPolling = false;
  String _connectionStatus = 'Disconnected';
  String? _processError;
  DateTime? _lastDataReceived;
  DateTime? _lastAlertTime;

  // Anomaly tracking with timestamps
  final Map<String, AnomalyTracker> _anomalyTrackers = {};

  final Map<String, bool> _severityFilters = {
    "Critical": true,
    "High": true,
    "Medium": true,
    "Low": true,
  };

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(AlertConfig.pollInterval, (timer) {
      _fetchHealthData();
    });
    _fetchHealthData(); // Initial fetch
  }

  Future<void> _fetchHealthData() async {
    if (_isPolling || !SimulationState.isConnected) return;
    _isPolling = true;

    try {
      final response = await http
          .get(Uri.parse('${AlertConfig.apiBaseUrl}/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _connectionStatus = 'Connected';
          _lastDataReceived = DateTime.now();
          _processError = null;
        });

        try {
          _processHealthData(data);
        } catch (e) {
          setState(() {
            _processError = 'Processing Error: $e';
          });
          print('Processing error: $e');
        }
      } else {
        setState(() {
          _connectionStatus = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection Error';
      });
      print('Error fetching health data: $e');
    } finally {
      _isPolling = false;
    }
  }

  void _processHealthData(Map<String, dynamic> data) {
    final predictionsRaw = data['latest_predictions'];
    if (predictionsRaw == null || predictionsRaw is! Map) return;

    final predictions = Map<String, dynamic>.from(predictionsRaw);

    for (var entry in predictions.entries) {
      final plantId = entry.key;
      final predictionRaw = entry.value;
      if (predictionRaw == null || predictionRaw is! Map) continue;

      final prediction = Map<String, dynamic>.from(predictionRaw);
      _trackAnomaly(plantId, prediction, data);
    }
  }

  /// NEW HACKATHON LOGIC:
  /// - Triggers when severity != "normal"
  /// - Must persist for 3 seconds (AlertConfig.anomalyDuration)
  /// - Creates multiple alerts for long anomalies (one per 3s window)
  void _trackAnomaly(
    String plantId,
    Map<String, dynamic> prediction,
    Map<String, dynamic> healthData,
  ) {
    final rawSeverity = (prediction['severity'] ?? 'normal')
        .toString()
        .toLowerCase();
    final isAbnormal = rawSeverity != 'normal';

    // Initialize tracker if it doesn't exist
    if (!_anomalyTrackers.containsKey(plantId)) {
      _anomalyTrackers[plantId] = AnomalyTracker();
    }

    final tracker = _anomalyTrackers[plantId]!;

    if (isAbnormal) {
      if (!tracker.isTracking) {
        // Start tracking this abnormal period
        tracker.startTracking(DateTime.now(), prediction);
      } else {
        // Update existing tracking with latest prediction
        tracker.updateTracking(prediction);

        // How long has this abnormal condition been going on?
        final duration = DateTime.now().difference(tracker.startTime!);

        if (duration >= AlertConfig.anomalyDuration) {
          final now = DateTime.now();
          if (_lastAlertTime == null ||
              now.difference(_lastAlertTime!) >= AlertConfig.coolDownDuration) {
            _createAlert(plantId, prediction, healthData, duration);
            _lastAlertTime = now;

            // Restart tracking after firing
            tracker.startTracking(now, prediction);
          }
        }
      }
    } else {
      // Back to normal -> reset tracking
      tracker.reset();
    }
  }

  void _createAlert(
    String plantId,
    Map<String, dynamic> prediction,
    Map<String, dynamic> healthData,
    Duration duration,
  ) {
    final severity = _mapSeverity(prediction['severity'] ?? 'normal');
    final anomalyScore = (prediction['raw_anomaly_score'] ?? 0.0).toDouble();
    final confidence = (prediction['confidence'] ?? 0.0).toDouble();
    final stability = (prediction['stability'] ?? 0.0).toDouble();

    // Build top causes detail
    String topCausesDetail = '';
    List<Map<String, dynamic>> topCauses = [];

    if (prediction['top_causes'] != null &&
        (prediction['top_causes'] as List).isNotEmpty) {
      topCauses = List<Map<String, dynamic>>.from(prediction['top_causes']);
      final causeSensors = topCauses.take(3).map((c) => c['sensor']).join(', ');
      topCausesDetail = 'Top contributing sensors: $causeSensors';
    }

    // Get sensor values
    String sensorValuesLog = '';
    if (healthData['latest_sensor_values'] != null) {
      final latestSensors = healthData['latest_sensor_values'];
      if (latestSensors is Map && latestSensors.containsKey(plantId)) {
        final sensorData = latestSensors[plantId];
        if (sensorData != null && sensorData['values'] != null) {
          final values = sensorData['values'] as Map<String, dynamic>;
          sensorValuesLog = values.entries
              .take(5)
              .map(
                (e) =>
                    '${e.key}: ${(e.value as num?)?.toStringAsFixed(2) ?? 'N/A'}',
              )
              .join('\n');
        }
      }
    }

    final newAlert = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "title": "AI Anomaly Detected - $plantId",
      "description": "Anomaly persisted for ${duration.inSeconds} seconds",
      "machine": plantId.toUpperCase().replaceAll('_', ' '),
      "time": _formatTime(DateTime.now()),
      "timestamp": DateTime.now(),
      "severity": severity,
      "rootCause": prediction['root_cause'] ?? 'Anomaly detected',
      "rootCauseDetail": topCausesDetail.isNotEmpty
          ? topCausesDetail
          : "Pattern detected by AI model - threshold: ${(healthData['threshold'] as num).toStringAsFixed(2)}",
      "action":
          prediction['recommendation'] ??
          'Monitor system closely and investigate',
      "additionalActions": [
        "Review sensor trends for the past hour",
        "Check maintenance logs for recent work",
        "Verify calibration of top contributing sensors",
      ],
      "eventLog":
          "Auto-generated alert for persistent anomaly\n"
          "Duration: ${duration.inSeconds} seconds\n"
          "Anomaly Score: ${anomalyScore.toStringAsFixed(3)}\n"
          "Threshold: ${(healthData['threshold'] as num).toStringAsFixed(3)}\n"
          "Confidence: ${confidence.toStringAsFixed(1)}%\n"
          "Stability: ${stability.toStringAsFixed(1)}%\n"
          "Rolling Average: ${(prediction['rolling_avg'] ?? 0.0).toStringAsFixed(3)}\n"
          "Rolling Std Dev: ${(prediction['rolling_std'] ?? 0.0).toStringAsFixed(3)}\n\n"
          "Recent Sensor Values:\n$sensorValuesLog",
      "rawData": {
        ...prediction,
        "top_causes": topCauses,
        "duration_seconds": duration.inSeconds,
      },
    };

    setState(() {
      _alerts.insert(0, newAlert);

      // Keep only max alerts
      if (_alerts.length > AlertConfig.maxAlerts) {
        _alerts = _alerts.sublist(0, AlertConfig.maxAlerts);
      }

      // Auto-select the new alert if it's the first one
      if (_selectedAlertIndex >= _alerts.length) {
        _selectedAlertIndex = 0;
      }
    });

    // Show notification
    // _showAlertNotification(newAlert);
  }

  void _deleteAlert(int index) {
    setState(() {
      if (index < _alerts.length) {
        _alerts.removeAt(index);

        // Adjust selected index if needed
        if (_selectedAlertIndex >= _alerts.length && _alerts.isNotEmpty) {
          _selectedAlertIndex = _alerts.length - 1;
        } else if (_alerts.isEmpty) {
          _selectedAlertIndex = 0;
        }
      }
    });
  }

  void _acknowledgeAlert(int index) {
    setState(() {
      if (index < _alerts.length) {
        _alerts[index]["acknowledged"] = true;
      }
    });
  }

  String _mapSeverity(String apiSeverity) {
    switch (apiSeverity.toLowerCase()) {
      case 'critical':
      case 'danger':
        return 'Critical';
      case 'high':
        return 'High';
      case 'warning':
        return 'Medium';
      case 'normal':
      case 'low':
      default:
        return 'Low';
    }
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}:"
        "${dateTime.second.toString().padLeft(2, '0')}";
  }

  List<Map<String, dynamic>> get _filteredAlerts {
    return _alerts.where((alert) {
      final severityMatch = _severityFilters[alert["severity"]] ?? false;
      // For now, just filter by severity
      // You can add sensor type filtering based on top_causes if needed
      return severityMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 1000;

        return Column(
          children: [
            _buildStatusBar(),
            Expanded(child: isWide ? _buildWideLayout() : _buildNarrowLayout()),
          ],
        );
      },
    );
  }

  Widget _buildStatusBar() {
    final statusColor = _connectionStatus == 'Connected'
        ? AppTheme.neonCyan
        : AppTheme.neonRed;

    final timeSinceUpdate = _lastDataReceived != null
        ? DateTime.now().difference(_lastDataReceived!)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.surfaceLight.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _connectionStatus,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (timeSinceUpdate != null) ...[
            const SizedBox(width: 16),
            Text(
              'Last update: ${timeSinceUpdate.inSeconds}s ago',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (_processError != null) ...[
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _processError!,
                style: const TextStyle(
                  color: AppTheme.neonOrange,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const Spacer(),
          Text(
            'Active Alerts: ${_filteredAlerts.length}',
            style: const TextStyle(
              color: AppTheme.neonCyan,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 260, child: _buildFiltersPanel()),
          const SizedBox(width: 20),
          Expanded(flex: 2, child: _buildAlertList()),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: _filteredAlerts.isEmpty
                ? _buildEmptyState()
                : _buildDetailPanel(_filteredAlerts[_selectedAlertIndex]),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFiltersPanel(),
        const SizedBox(height: 16),
        _buildAlertList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Alerts will appear when anomalies persist for 3 seconds',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            if (_connectionStatus != 'Connected')
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neonRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.neonRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.neonRed,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Waiting for connection...',
                      style: const TextStyle(
                        color: AppTheme.neonRed,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Alert Filter Controls",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(
                  "Critical",
                  AppTheme.neonRed,
                  _severityFilters["Critical"]!,
                ),
                _buildFilterChip(
                  "High",
                  AppTheme.neonOrange,
                  _severityFilters["High"]!,
                ),
                _buildFilterChip(
                  "Medium",
                  Colors.yellow.shade700,
                  _severityFilters["Medium"]!,
                ),
                _buildFilterChip(
                  "Low",
                  AppTheme.neonCyan,
                  _severityFilters["Low"]!,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _alerts.clear();
                  _anomalyTrackers.clear();
                });
              },
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear All Alerts'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonRed.withValues(alpha: 0.1),
                foregroundColor: AppTheme.neonRed,
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, Color color, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _severityFilters[label] = !_severityFilters[label]!;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? color
                : AppTheme.surfaceLight.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? color : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAlertList() {
    if (!SimulationState.isConnected) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.surfaceLight.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.link_off,
                color: AppTheme.neonOrange.withValues(alpha: 0.5),
                size: 64,
              ),
              const SizedBox(height: 20),
              const Text(
                'Simulation Disconnected',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please click "Connect Model" in the simulation popup to begin receiving alerts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final filteredAlerts = _filteredAlerts;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (filteredAlerts.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  _alerts.isEmpty
                      ? 'No alerts yet. Monitoring for anomalies...'
                      : 'No alerts match current filters',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: filteredAlerts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildAlertCard(filteredAlerts[index], index);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, int index) {
    final isSelected = index == _selectedAlertIndex;
    final isAcknowledged = alert["acknowledged"] == true;
    Color severityColor = _getSeverityColor(alert["severity"]);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAlertIndex = index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isAcknowledged
              ? AppTheme.background.withValues(alpha: 0.5)
              : AppTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? severityColor
                : AppTheme.surfaceLight.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alert["title"],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isAcknowledged
                                    ? AppTheme.textSecondary
                                    : AppTheme.textPrimary,
                                decoration: isAcknowledged
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (isAcknowledged)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.neonCyan.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ACK',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.neonCyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alert["description"],
                        style: TextStyle(
                          color: AppTheme.textPrimary.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            alert["machine"],
                            style: TextStyle(
                              fontSize: 12,
                              color: severityColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            " • ",
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            alert["time"],
                            style: TextStyle(
                              fontSize: 12,
                              color: severityColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppTheme.textSecondary,
                onPressed: () => _deleteAlert(index),
                tooltip: 'Delete alert',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(Map<String, dynamic> alert) {
    Color severityColor = _getSeverityColor(alert["severity"]);
    final isAcknowledged = alert["acknowledged"] == true;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.neonOrange.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    alert["title"],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    alert["severity"],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16),
              child: _buildAnomalyChart(alert, severityColor),
            ),
            const SizedBox(height: 24),
            const Text(
              "Root-Cause Analysis",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert["rootCause"],
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert["rootCauseDetail"] ?? "Pattern detected by AI model",
                    style: TextStyle(
                      color: AppTheme.textPrimary.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Recommended Actions",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.neonOrange,
                    size: 14,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alert["action"],
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (alert["additionalActions"] != null &&
                (alert["additionalActions"] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              ...((alert["additionalActions"] as List).map((action) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.neonOrange,
                          size: 14,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            action,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList()),
            ],
            if (alert["eventLog"] != null) ...[
              const SizedBox(height: 24),
              const Text(
                "Full Event Log",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alert["eventLog"],
                  style: TextStyle(
                    color: AppTheme.textPrimary.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    isAcknowledged ? "Acknowledged" : "Acknowledge",
                    isAcknowledged
                        ? AppTheme.neonCyan.withValues(alpha: 0.5)
                        : AppTheme.neonCyan,
                    enabled: !isAcknowledged,
                    onPressed: !isAcknowledged
                        ? () => _acknowledgeAlert(_selectedAlertIndex)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    "Delete",
                    AppTheme.neonRed,
                    onPressed: () => _deleteAlert(_selectedAlertIndex),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyChart(Map<String, dynamic> alert, Color severityColor) {
    final rawData = alert["rawData"];

    if (rawData != null && rawData["top_causes"] != null) {
      final topCauses = rawData["top_causes"] as List;

      if (topCauses.isNotEmpty) {
        List<FlSpot> spots = [];
        for (int i = 0; i < topCauses.length && i < 10; i++) {
          final impact = (topCauses[i]["impact"] ?? 0.0).toDouble();
          spots.add(FlSpot(i.toDouble(), impact));
        }

        if (spots.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sensor Impact Analysis",
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: AppTheme.surfaceLight.withValues(alpha: 0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < topCauses.length) {
                              final sensor =
                                  topCauses[index]["sensor"] as String;
                              final shortName = sensor.split('_').first;
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  shortName,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: severityColor,
                        barWidth: 3,
                        belowBarData: BarAreaData(
                          show: true,
                          color: severityColor.withValues(alpha: 0.2),
                        ),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: severityColor,
                              strokeWidth: 2,
                              strokeColor: AppTheme.background,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      }
    }

    // Default chart showing anomaly score over time (placeholder)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Anomaly Score Trend",
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 1),
                    FlSpot(1, 3),
                    FlSpot(2, 2),
                    FlSpot(3, 5),
                    FlSpot(4, 3),
                    FlSpot(5, 6),
                  ],
                  isCurved: true,
                  color: severityColor,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    color: severityColor.withValues(alpha: 0.2),
                  ),
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    Color color, {
    bool enabled = true,
    VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: enabled ? color : color.withValues(alpha: 0.3)),
        foregroundColor: enabled ? color : color.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case "Critical":
        return AppTheme.neonRed;
      case "High":
        return AppTheme.neonOrange;
      case "Medium":
        return Colors.yellow.shade700;
      default:
        return AppTheme.neonCyan;
    }
  }
}

// Helper class to track anomaly state
class AnomalyTracker {
  DateTime? startTime;
  bool isTracking = false;
  bool alertCreatedForThisPeriod = false;
  Map<String, dynamic>? lastPrediction;

  void startTracking(DateTime time, Map<String, dynamic> prediction) {
    startTime = time;
    isTracking = true;
    alertCreatedForThisPeriod = false;
    lastPrediction = prediction;
  }

  void updateTracking(Map<String, dynamic> prediction) {
    lastPrediction = prediction;
  }

  void markAlertCreated() {
    alertCreatedForThisPeriod = true;
  }

  void reset() {
    startTime = null;
    isTracking = false;
    alertCreatedForThisPeriod = false;
    lastPrediction = null;
  }
}
