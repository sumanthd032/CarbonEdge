import 'dart:async';
import 'dart:math';

import 'package:carbonedge/data/machine_data.dart';
import 'package:carbonedge/services/kiln_service.dart';
import 'package:carbonedge/services/machine_simulation_service.dart';
import 'package:carbonedge/theme/app_theme.dart';
import 'package:carbonedge/widgets/dashboard_right_panel.dart';
import 'package:carbonedge/widgets/kpi_card.dart';
import 'package:carbonedge/widgets/neon_card.dart';
import 'package:carbonedge/widgets/plant_explorer.dart';
import 'package:carbonedge/widgets/plant_heatmap.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<FlSpot> _energySpots = [];
  final List<FlSpot> _fuelSpots = [];
  final List<FlSpot> _pressureSpots = [];
  late Timer _timer;
  final Random _random = Random();
  double _xValue = 0;
  String _selectedMachine = "Kiln A";
  String _selectedChartTab = "Temperature";

  final KilnService _kilnService = KilnService();
  Map<String, dynamic>? _kilnData;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _generateInitialData();

    _kilnService.connect();
    _subscription = _kilnService.dataStream.listen(
      (data) {
        // print("WebSocket Data: $data"); // Debugging
        if (mounted) {
          // Only update state if we have valid sensor data
          if (data.containsKey('latest_sensor_values') &&
              data['latest_sensor_values'] is Map &&
              data['latest_sensor_values'].containsKey('plant_1')) {
            final plantData = data['latest_sensor_values']['plant_1'];
            if (plantData != null && plantData.containsKey('values')) {
              setState(() {
                _kilnData = plantData['values'];
              });
            }
          }
          // If the data doesn't contain the expected structure, we simply ignore it
          // and keep the last known good values.
        }
      },
      onError: (err) {
        print("Stream Error: $err");
      },
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateData();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _subscription?.cancel();
    _kilnService.dispose();
    super.dispose();
  }

  void _generateInitialData() {
    _regenerateDataForMachine(_selectedMachine);
  }

  void _regenerateDataForMachine(String machineName) {
    _energySpots.clear();
    _fuelSpots.clear();
    _pressureSpots.clear();
    _xValue = 0;

    // Seed random based on machine name length to give deterministic but different starting points
    int seed = machineName.length;

    for (int i = 0; i < 30; i++) {
      double energy = 40 + sin(i * 0.2 + seed) * 10 + _random.nextDouble() * 5;
      double fuel = 30 + cos(i * 0.2 + seed) * 8 + _random.nextDouble() * 4;
      double pressure =
          25 + sin(i * 0.15 + seed) * 6 + _random.nextDouble() * 3;
      _energySpots.add(FlSpot(i.toDouble(), energy));
      _fuelSpots.add(FlSpot(i.toDouble(), fuel));
      _pressureSpots.add(FlSpot(i.toDouble(), pressure));
      _xValue = i.toDouble();
    }
  }

  // Removed _fetchData as we use stream now

  void _updateData() {
    if (!mounted) return;

    // _fetchData(); // Removed, using stream

    setState(() {
      _xValue += 1;
      // Add some variation based on selected machine
      double offset = _selectedMachine.length.toDouble();
      double energy =
          40 + sin(_xValue * 0.2 + offset) * 10 + _random.nextDouble() * 5;
      double fuel =
          30 + cos(_xValue * 0.2 + offset) * 8 + _random.nextDouble() * 4;
      double pressure =
          25 + sin(_xValue * 0.15 + offset) * 6 + _random.nextDouble() * 3;

      _energySpots.add(FlSpot(_xValue, energy));
      _fuelSpots.add(FlSpot(_xValue, fuel));
      _pressureSpots.add(FlSpot(_xValue, pressure));

      if (_energySpots.length > 30) {
        _energySpots.removeAt(0);
        _fuelSpots.removeAt(0);
        _pressureSpots.removeAt(0);
      }
    });
  }

  void _onMachineSelected(String machineName) {
    setState(() {
      _selectedMachine = machineName;
      _regenerateDataForMachine(machineName);
      if (machineName != "Kiln A") {
        _kilnData = null; // Clear kiln data if not selected
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 1200;

        if (isWide) {
          return Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlantExplorer(onMachineSelected: _onMachineSelected),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildKPIs(isWide),
                          const SizedBox(height: 24),
                          _buildMainChart(isWide: true),
                          const SizedBox(height: 24),
                          _buildSecondaryCharts(),
                          const SizedBox(height: 24),
                          PlantHeatmap(
                            isMobile: false,
                            selectedMachine: _selectedMachine,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const DashboardRightPanel(),
                ],
              ),
            ],
          );
        } else {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMobileHeader(),
                const SizedBox(height: 24),
                _buildKPIs(isWide),
                const SizedBox(height: 24),
                _buildMainChart(isWide: false),
                const SizedBox(height: 24),
                _buildSecondaryCharts(),
                const SizedBox(height: 24),
                PlantHeatmap(isMobile: true, selectedMachine: _selectedMachine),
                const SizedBox(height: 24),
                const DashboardRightPanel(isMobile: true),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$_selectedMachine Dashboard",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Real-time metrics from SCADA and IIoT sensors.",
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("View:", style: TextStyle(color: AppTheme.textSecondary)),
          DropdownButton<String>(
            value: _selectedMachine,
            dropdownColor: AppTheme.surface,
            underline: const SizedBox(),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.textSecondary,
            ),
            items: MachineData.machines
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedMachine = val!;
              });
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getKPIsForMachine(String machineName) {
    final random = Random(machineName.hashCode);

    // Helper to get random trend
    String getTrend() => random.nextBool() ? "↗" : "↓";
    bool getPos() => random.nextBool();

    if (machineName == "Kiln A") {
      final data = _kilnData ?? MachineSimulationService.getKilnData();

      String fmt(dynamic val, [int decimals = 0]) {
        if (val == null) return "--";
        if (val is num) return val.toStringAsFixed(decimals);
        return val.toString();
      }

      return [
        {
          "title": "Kiln Temp",
          "value": fmt(data["kiln_temperature"], 0),
          "unit": "°C",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.thermostat,
          "color": AppTheme.neonOrange,
        },
        {
          "title": "Feed Rate",
          "value": fmt(data["feed_rate"], 1),
          "unit": "t/h",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.input,
          "color": AppTheme.neonCyan,
        },
        {
          "title": "Fuel Flow",
          "value": fmt(data["fuel_flow_rate"], 0),
          "unit": "kg/h",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.local_gas_station,
          "color": AppTheme.neonRed,
        },
        {
          "title": "Kiln Pressure",
          "value": fmt(data["kiln_pressure"], 2),
          "unit": "mbar",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.speed,
          "color": AppTheme.neonGreen,
        },
        {
          "title": "Exhaust O2",
          "value": fmt(data["exhaust_o2"], 2),
          "unit": "%",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.science,
          "color": AppTheme.neonGreen,
        },
        {
          "title": "Exhaust CO",
          "value": fmt(data["exhaust_co"], 0),
          "unit": "ppm",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.warning,
          "color": AppTheme.neonRed,
        },
        {
          "title": "Clinker Temp",
          "value": fmt(data["clinker_temp"], 0),
          "unit": "°C",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.thermostat,
          "color": AppTheme.neonOrange,
        },
        {
          "title": "Rotary Speed",
          "value": fmt(data["rotary_speed_rpm"], 2),
          "unit": "rpm",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.rotate_right,
          "color": AppTheme.neonCyan,
        },
      ];
    } else if (machineName.contains("Kiln")) {
      double tempBase = 1000 + (random.nextInt(5) * 200).toDouble();
      return [
        {
          "title": "Kiln Temperature",
          "value": (tempBase + random.nextInt(150)).toString(),
          "unit": "°C",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.thermostat,
          "color": AppTheme.neonOrange,
        },
        {
          "title": "Airflow Rate",
          "value": (15000 + random.nextInt(8000)).toString(),
          "unit": "m³/s",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.air,
          "color": AppTheme.neonCyan,
        },
        {
          "title": "Fuel Usage",
          "value": (200 + random.nextInt(300)).toString(),
          "unit": "L/hr",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.local_gas_station,
          "color": AppTheme.neonRed,
        },
        {
          "title": "O2 Level",
          "value": (2 + random.nextDouble() * 3).toStringAsFixed(1),
          "unit": "%",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.science,
          "color": AppTheme.neonGreen,
        },
        {
          "title": "Clinker Output",
          "value": (150 + random.nextInt(50)).toString(),
          "unit": "t/hr",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.precision_manufacturing,
          "color": AppTheme.neonOrange,
        },
      ];
    } else if (machineName.contains("Motor")) {
      return [
        {
          "title": "Vibration",
          "value": (0.2 + random.nextDouble() * 2.0).toStringAsFixed(2),
          "unit": "mm/s",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.vibration,
          "color": AppTheme.neonCyan,
        },
        {
          "title": "RPM",
          "value": (1400 + random.nextInt(100)).toString(),
          "unit": "rpm",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.speed,
          "color": AppTheme.neonGreen,
        },
        {
          "title": "Current",
          "value": (45 + random.nextDouble() * 10).toStringAsFixed(1),
          "unit": "A",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.electric_bolt,
          "color": AppTheme.neonOrange,
        },
        {
          "title": "Bearing Temp",
          "value": (60 + random.nextInt(20)).toString(),
          "unit": "°C",
          "trend": getTrend(),
          "isPositive": getPos(),
          "icon": Icons.thermostat,
          "color": AppTheme.neonRed,
        },
      ];
    } else {
      // Default / Generic
      return [
        {
          "title": "Status",
          "value": "Active",
          "unit": "",
          "trend": "-",
          "isPositive": true,
          "icon": Icons.info,
          "color": AppTheme.neonGreen,
        },
        {
          "title": "Efficiency",
          "value": (80 + random.nextInt(15)).toString(),
          "unit": "%",
          "trend": getTrend(),
          "isPositive": true,
          "icon": Icons.trending_up,
          "color": AppTheme.neonCyan,
        },
      ];
    }
  }

  Widget _buildKPIs(bool isWide) {
    final kpis = _getKPIsForMachine(_selectedMachine);

    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        int count = width > 800 ? 4 : 2;
        double ratio = width > 800 ? 1.2 : 1.5;

        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: ratio,
          children: kpis.map((kpi) {
            return KPICard(
              title: kpi["title"],
              value: kpi["value"],
              unit: kpi["unit"],
              trend: kpi["trend"],
              isPositiveTrend: kpi["isPositive"],
              accentColor: kpi["color"],
              icon: kpi["icon"],
              isWeb: isWide,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMainChart({bool isWide = false}) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChartTab(
                  "Temperature",
                  _selectedChartTab == "Temperature",
                  isWide: isWide,
                ),
                _buildChartTab(
                  "Vibration",
                  _selectedChartTab == "Vibration",
                  isWide: isWide,
                ),
                _buildChartTab(
                  "Pressure",
                  _selectedChartTab == "Pressure",
                  isWide: isWide,
                ),
                _buildChartTab(
                  "Load",
                  _selectedChartTab == "Load",
                  isWide: isWide,
                ),
                _buildChartTab(
                  "Airflow",
                  _selectedChartTab == "Airflow",
                  isWide: isWide,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.surfaceLight.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _energySpots,
                    isCurved: true,
                    color: AppTheme.neonOrange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.neonOrange.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: _fuelSpots,
                    isCurved: true,
                    color: AppTheme.neonCyan,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.neonCyan.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: _pressureSpots,
                    isCurved: true,
                    color: AppTheme.neonGreen,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(label: "Temperature", color: AppTheme.neonOrange),
              SizedBox(width: 16),
              _LegendItem(label: "Vibration", color: AppTheme.neonCyan),
              SizedBox(width: 16),
              _LegendItem(label: "Pressure", color: AppTheme.neonGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryCharts() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 800;

        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildRadarChart()),
                const SizedBox(width: 16),
                Expanded(child: _buildBarChart()),
                const SizedBox(width: 16),
                Expanded(child: _buildPieChart()),
              ],
            ),
          );
        } else {
          return Column(
            children: [
              _buildRadarChart(),
              const SizedBox(height: 16),
              _buildBarChart(),
              const SizedBox(height: 16),
              _buildPieChart(),
            ],
          );
        }
      },
    );
  }

  List<RadarEntry> _getRadarData(String machineName) {
    final random = Random(machineName.hashCode);
    return List.generate(6, (index) {
      return RadarEntry(value: 60 + random.nextDouble() * 40);
    });
  }

  Widget _buildRadarChart() {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Equipment Health Score",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Multi-dimensional analysis",
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                radarBorderData: BorderSide(
                  color: AppTheme.surfaceLight.withValues(alpha: 0.3),
                  width: 2,
                ),
                gridBorderData: BorderSide(
                  color: AppTheme.surfaceLight.withValues(alpha: 0.3),
                  width: 1,
                ),
                tickBorderData: const BorderSide(color: Colors.transparent),
                tickCount: 5,
                ticksTextStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
                radarBackgroundColor: Colors.transparent,
                dataSets: [
                  RadarDataSet(
                    fillColor: AppTheme.neonCyan.withValues(alpha: 0.2),
                    borderColor: AppTheme.neonCyan,
                    borderWidth: 3,
                    dataEntries: _getRadarData(_selectedMachine),
                  ),
                ],
                getTitle: (index, angle) {
                  const titles = [
                    'Temp',
                    'Vibration',
                    'Pressure',
                    'Flow',
                    'Power',
                    'Efficiency',
                  ];
                  return RadarChartTitle(text: titles[index], angle: angle);
                },
                titleTextStyle: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _getBarChartData(String machineName) {
    final random = Random(machineName.hashCode);
    return List.generate(6, (index) {
      double value = 60 + random.nextDouble() * 50;
      Color color = value > 100
          ? AppTheme.neonRed
          : (value > 80 ? AppTheme.neonCyan : AppTheme.neonOrange);
      return _buildBarGroup(index, value, color);
    });
  }

  Widget _buildBarChart() {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hourly Production Rate",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Last 6 hours comparison",
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 120,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const hours = [
                          '14:00',
                          '15:00',
                          '16:00',
                          '17:00',
                          '18:00',
                          '19:00',
                        ];
                        if (value.toInt() >= 0 &&
                            value.toInt() < hours.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              hours[value.toInt()],
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.surfaceLight.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _getBarChartData(_selectedMachine),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 120,
            color: AppTheme.surfaceLight.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getPieChartData(String machineName) {
    final random = Random(machineName.hashCode);
    double v1 = 20 + random.nextDouble() * 20;
    double v2 = 20 + random.nextDouble() * 20;
    double v3 = 20 + random.nextDouble() * 20;
    double v4 = 100 - v1 - v2 - v3;

    return [
      PieChartSectionData(
        value: v1,
        title: '${v1.toInt()}%',
        color: AppTheme.neonOrange,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: v2,
        title: '${v2.toInt()}%',
        color: AppTheme.neonCyan,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: v3,
        title: '${v3.toInt()}%',
        color: AppTheme.neonGreen,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: v4,
        title: '${v4.toInt()}%',
        color: AppTheme.neonRed,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildPieChart() {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Energy Distribution",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Current consumption breakdown",
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    sections: _getPieChartData(_selectedMachine),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '4,500',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'kW Total',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _LegendItem(label: "Kiln", color: AppTheme.neonOrange),
              _LegendItem(label: "Motors", color: AppTheme.neonCyan),
              _LegendItem(label: "HVAC", color: AppTheme.neonGreen),
              _LegendItem(label: "Other", color: AppTheme.neonRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab(String label, bool isSelected, {bool isWide = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartTab = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceLight : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.textSecondary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontSize: isWide ? 14 : 12,
            fontWeight: isWide && isSelected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
