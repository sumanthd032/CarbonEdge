import 'dart:convert';
import 'dart:typed_data';

import 'package:carbonedge/helpers/file_export_helper.dart';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedReportType = "Monthly Summary";
  String selectedDateRange = "Last 30 Days";
  String selectedSnapshot = "Current Baseline";

  final List<String> snapshotOptions = [
    "Current Baseline",
    "Q1 2024 Summary",
    "Peak Production Cycle",
    "Maintenance Downtime",
  ];

  final Map<String, List<Map<String, dynamic>>> hardcodedSnapshots = {
    "Current Baseline": [
      {'month': 'Jan', 'actual': 42.0, 'predicted': 38.0, 'target': 30.0},
      {'month': 'Feb', 'actual': 45.0, 'predicted': 40.0, 'target': 31.0},
      {'month': 'Mar', 'actual': 40.0, 'predicted': 39.0, 'target': 30.0},
      {'month': 'Apr', 'actual': 38.0, 'predicted': 37.0, 'target': 29.0},
      {'month': 'May', 'actual': 36.0, 'predicted': 35.0, 'target': 28.0},
      {'month': 'Jun', 'actual': 34.0, 'predicted': 34.0, 'target': 27.0},
    ],
    "Q1 2024 Summary": [
      {'month': 'Jan', 'actual': 55.0, 'predicted': 38.0, 'target': 30.0},
      {'month': 'Feb', 'actual': 58.0, 'predicted': 40.0, 'target': 31.0},
      {'month': 'Mar', 'actual': 52.0, 'predicted': 39.0, 'target': 30.0},
      {'month': 'Apr', 'actual': 48.0, 'predicted': 37.0, 'target': 29.0},
      {'month': 'May', 'actual': 45.0, 'predicted': 35.0, 'target': 28.0},
      {'month': 'Jun', 'actual': 42.0, 'predicted': 34.0, 'target': 27.0},
    ],
    "Peak Production Cycle": [
      {'month': 'Jan', 'actual': 72.0, 'predicted': 68.0, 'target': 60.0},
      {'month': 'Feb', 'actual': 75.0, 'predicted': 70.0, 'target': 61.0},
      {'month': 'Mar', 'actual': 70.0, 'predicted': 69.0, 'target': 60.0},
      {'month': 'Apr', 'actual': 68.0, 'predicted': 67.0, 'target': 59.0},
      {'month': 'May', 'actual': 66.0, 'predicted': 65.0, 'target': 58.0},
      {'month': 'Jun', 'actual': 64.0, 'predicted': 64.0, 'target': 57.0},
    ],
    "Maintenance Downtime": [
      {'month': 'Jan', 'actual': 12.0, 'predicted': 15.0, 'target': 10.0},
      {'month': 'Feb', 'actual': 15.0, 'predicted': 18.0, 'target': 11.0},
      {'month': 'Mar', 'actual': 10.0, 'predicted': 12.0, 'target': 10.0},
      {'month': 'Apr', 'actual': 8.0, 'predicted': 10.0, 'target': 9.0},
      {'month': 'May', 'actual': 6.0, 'predicted': 8.0, 'target': 8.0},
      {'month': 'Jun', 'actual': 5.0, 'predicted': 6.0, 'target': 7.0},
    ],
  };

  List<Map<String, dynamic>> get emissionsData =>
      hardcodedSnapshots[selectedSnapshot]!;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Reports & ESG Analytics",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          // Top Row: ESG Score + Chart
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildESGScoreCard()),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: _buildEmissionsChart()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildESGScoreCard(),
                    const SizedBox(height: 24),
                    _buildEmissionsChart(),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 40),
          _buildGenerateReportSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildESGScoreCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text(
              "ESG Performance Score",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            CircularPercentIndicator(
              radius: 100,
              lineWidth: 16,
              percent: 0.88,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "88",
                    style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Excellent",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              progressColor: Colors.green,
              backgroundColor: Colors.grey.shade300,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _ESGStat(
                  label: "Environmental",
                  value: "92%",
                  color: Colors.green,
                ),
                _ESGStat(label: "Social", value: "85%", color: Colors.blue),
                _ESGStat(
                  label: "Governance",
                  value: "87%",
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmissionsChart() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "CO₂ Emissions (tCO₂e)",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) =>
                            Text(value.toInt().toString()),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                          ];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              months[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: emissionsData.asMap().entries.map((entry) {
                    int index = entry.key;
                    var data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['actual'],
                          color: Colors.red.shade400,
                          width: 16,
                        ),
                        BarChartRodData(
                          toY: data['predicted'],
                          color: Colors.orange.shade600,
                          width: 16,
                        ),
                        BarChartRodData(
                          toY: data['target'],
                          color: Colors.green.shade600,
                          width: 16,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _LegendItem(color: Colors.red, label: "Actual"),
                SizedBox(width: 24),
                _LegendItem(color: Colors.orange, label: "Predicted"),
                SizedBox(width: 24),
                _LegendItem(color: Colors.green, label: "Target"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateReportSection() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Generate New Report",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final bool row = constraints.maxWidth > 600;
                return row
                    ? Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              "Report Type",
                              selectedReportType,
                              [
                                "Monthly Summary",
                                "Quarterly Report",
                                "Annual ESG Report",
                              ],
                              (val) =>
                                  setState(() => selectedReportType = val!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              "Date Range",
                              selectedDateRange,
                              [
                                "Last 7 Days",
                                "Last 30 Days",
                                "Year to Date",
                                "Custom Range",
                              ],
                              (val) => setState(() => selectedDateRange = val!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              "Data Snapshot",
                              selectedSnapshot,
                              snapshotOptions,
                              (val) => setState(() => selectedSnapshot = val!),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildDropdown(
                            "Report Type",
                            selectedReportType,
                            [
                              "Monthly Summary",
                              "Quarterly Report",
                              "Annual ESG Report",
                            ],
                            (val) => setState(() => selectedReportType = val!),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            "Date Range",
                            selectedDateRange,
                            [
                              "Last 7 Days",
                              "Last 30 Days",
                              "Year to Date",
                              "Custom Range",
                            ],
                            (val) => setState(() => selectedDateRange = val!),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            "Select Hardcoded Data Snapshot",
                            selectedSnapshot,
                            snapshotOptions,
                            (val) => setState(() => selectedSnapshot = val!),
                          ),
                        ],
                      );
              },
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _generateEsgPdf(),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Export as PDF"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportExcel(),
                  icon: const Icon(Icons.table_chart),
                  label: const Text("Export as Excel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportCSV(),
                  icon: const Icon(Icons.download),
                  label: const Text("Export as CSV"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  // EXPORT FUNCTIONS
  Future<void> _generateEsgPdf() async {
    final pdf = pw.Document();
    final netImage = await networkImage(
      'https://cdn-icons-png.flaticon.com/512/2964/2964514.png',
    ); // Placeholder logo if asset fails

    pdf.addPage(pw.Page(build: (context) => _buildCoverPage(netImage)));

    pdf.addPage(pw.Page(build: (context) => _buildExecutiveSummary()));

    pdf.addPage(pw.Page(build: (context) => _buildEmissionsPage()));

    pdf.addPage(pw.Page(build: (context) => _buildEnvironmentalMetrics()));

    pdf.addPage(pw.Page(build: (context) => _buildMachineSummary()));

    pdf.addPage(pw.Page(build: (context) => _buildGovernancePage()));

    pdf.addPage(pw.Page(build: (context) => _buildRecommendations()));

    pdf.addPage(pw.Page(build: (context) => _buildAppendix()));

    // Save and Open
    final bytes = await pdf.save();

    // Share/Download
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'CarbonEdge_ESG_Report.pdf',
    );
  }

  // PAGE 1: COVER PAGE
  pw.Widget _buildCoverPage(pw.ImageProvider logo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Image(logo, width: 100, height: 100),
        pw.SizedBox(height: 40),
        pw.Text(
          "CarbonEdge AI",
          style: pw.TextStyle(
            fontSize: 40,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green900,
          ),
        ),
        pw.Text(
          "ESG Performance Report",
          style: pw.TextStyle(fontSize: 24, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 20),
        pw.Text("Plant: Mock Plant A | Reporting Period: Last 30 Days"),
        pw.SizedBox(height: 60),

        // ESG Score Ring
        pw.Stack(
          alignment: pw.Alignment.center,
          children: [
            pw.Container(
              width: 200,
              height: 200,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: PdfColors.green, width: 10),
              ),
            ),
            pw.Column(
              children: [
                pw.Text(
                  "88",
                  style: pw.TextStyle(
                    fontSize: 60,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  "Excellent",
                  style: pw.TextStyle(fontSize: 20, color: PdfColors.green),
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 60),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            _buildScoreBadge("Environmental", "92%", PdfColors.green),
            _buildScoreBadge("Social", "85%", PdfColors.blue),
            _buildScoreBadge("Governance", "87%", PdfColors.purple),
          ],
        ),

        pw.Spacer(),
        pw.Divider(),
        pw.Text(
          "Generated by CarbonEdge AI — Industrial Optimization Platform",
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
      ],
    );
  }

  pw.Widget _buildScoreBadge(String label, String score, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          score,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
      ],
    );
  }

  // PAGE 2: EXECUTIVE SUMMARY
  pw.Widget _buildExecutiveSummary() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader("Executive Summary"),
        pw.SizedBox(height: 20),
        pw.Text(
          "CarbonEdge AI analyzes SCADA/IIoT signals from industrial assets, predicts inefficiencies, and generates automated ESG intelligence. This report summarizes the latest environmental and performance metrics.",
          style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
        ),
        pw.SizedBox(height: 30),
        pw.Text(
          "Key Highlights",
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        _buildBulletPoint(
          "Energy consumption reduced by 12.4% compared to baseline.",
        ),
        _buildBulletPoint("CO2 emissions are 8.9% below the monthly target."),
        _buildBulletPoint(
          "14 anomaly events were prevented by AI predictive maintenance.",
        ),

        pw.SizedBox(height: 40),
        pw.Text(
          "Impact Summary",
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow(["Metric", "Value", "Status"], isHeader: true),
            _buildTableRow(["Energy Saved", "12.4%", "Positive"]),
            _buildTableRow(["CO2 Reduction", "8.9%", "Positive"]),
            _buildTableRow(["Anomalies Prevented", "14", "Excellent"]),
          ],
        ),
      ],
    );
  }

  // PAGE 3: CO2 EMISSIONS ANALYSIS
  pw.Widget _buildEmissionsPage() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader("CO2 Emissions Analysis"),
        pw.SizedBox(height: 20),
        pw.Text("Monthly emissions vs predicted and target values (tCO2e)."),
        pw.SizedBox(height: 40),

        // Simple Bar Chart Simulation using Containers
        pw.Container(
          height: 200,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: emissionsData.map((data) {
              final double actualHeight = (data['actual'] as double) * 3;
              final double targetHeight = (data['target'] as double) * 3;
              return pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 15,
                        height: actualHeight,
                        color: PdfColors.red,
                      ),
                      pw.SizedBox(width: 2),
                      pw.Container(
                        width: 15,
                        height: targetHeight,
                        color: PdfColors.green,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    data['month'],
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            _buildLegendItem(PdfColors.red, "Actual"),
            pw.SizedBox(width: 20),
            _buildLegendItem(PdfColors.green, "Target"),
          ],
        ),

        pw.SizedBox(height: 40),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow([
              "Month",
              "Actual",
              "Predicted",
              "Target",
            ], isHeader: true),
            ...emissionsData.map(
              (e) => _buildTableRow([
                e['month'],
                e['actual'].toString(),
                e['predicted'].toString(),
                e['target'].toString(),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  // PAGE 4: ENVIRONMENTAL METRICS
  pw.Widget _buildEnvironmentalMetrics() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader("Environmental Metrics"),
        pw.SizedBox(height: 20),
        _buildMetricRow("Total Grid Energy", "421 MWh"),
        _buildMetricRow("Diesel Generator Energy", "62 MWh"),
        _buildMetricRow("Water Consumption", "192 m3"),
        _buildMetricRow("Waste Generated (Solid)", "4.6 tons"),
        _buildMetricRow("Fuel Efficiency Loss", "3.2% (AI Detected)"),
      ],
    );
  }

  // PAGE 5: MACHINE & TAG SUMMARY
  pw.Widget _buildMachineSummary() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader("Machine & Tag Summary"),
        pw.SizedBox(height: 20),
        pw.Text("Real-time data snapshot from Digital Twin."),
        pw.SizedBox(height: 20),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow(["Machine", "Status", "Key Metric"], isHeader: true),
            _buildTableRow(["Kiln A", "Running", "145°C | 0.12g vib"]),
            _buildTableRow(["Kiln B", "Running", "148°C | 0.45g vib"]),
            _buildTableRow(["Fan 3", "Running", "850 rpm | 0.12g"]),
            _buildTableRow(["Power Unit", "Active", "480V | 81% load"]),
          ],
        ),
        pw.SizedBox(height: 40),
        pw.Text(
          "System Stats",
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        _buildBulletPoint("Machines Detected: 4"),
        _buildBulletPoint("Tags Monitored: 242"),
        _buildBulletPoint("Data Ingestion Rate: 1.2 MB/s"),
      ],
    );
  }

  // PAGE 6: GOVERNANCE & COMPLIANCE
  pw.Widget _buildGovernancePage() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader("Governance & Compliance"),
        pw.SizedBox(height: 20),
        _buildMetricRow("Safety Compliance Score", "96%"),
        _buildMetricRow("Audits Completed", "4"),
        pw.SizedBox(height: 30),
        pw.Text(
          "Standards Adherence",
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        _buildBulletPoint("ISO 50001 - Energy Management"),
        _buildBulletPoint("GHG Protocol - Scope 1 & 2"),
        _buildBulletPoint("CSRD - Corporate Sustainability Reporting"),
        pw.SizedBox(height: 30),
        pw.Text(
          "Automated Alerts",
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        _buildBulletPoint("High Temperature Triggers: 3"),
        _buildBulletPoint("Vibration Threshold Alerts: 2"),
      ],
    );
  }

  // PAGE 7: CONCLUSION & RECOMMENDATIONS
  pw.Widget _buildRecommendations() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader("Conclusion & Recommendations"),
        pw.SizedBox(height: 20),
        pw.Text(
          "AI-Suggested Operational Improvements:",
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),
        _buildBulletPoint(
          "Tune kiln airflow — predicted 6.2% energy reduction",
        ),
        _buildBulletPoint(
          "Fan speed stability improvement — predicted 2.8% efficiency increase",
        ),
        _buildBulletPoint(
          "Implement heat-recovery cycle monitoring — predicted 4.5% CO2 reduction",
        ),
        pw.SizedBox(height: 40),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.green50,
            border: pw.Border.all(color: PdfColors.green),
          ),
          child: pw.Text(
            "By implementing these recommendations, CarbonEdge predicts a potential total energy saving of 9% over the next quarter.",
            style: const pw.TextStyle(color: PdfColors.green900),
          ),
        ),
      ],
    );
  }

  // PAGE 8: APPENDIX
  pw.Widget _buildAppendix() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader("Appendix"),
        pw.SizedBox(height: 20),
        pw.Text(
          "Data Sources",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          "All data is aggregated from on-site SCADA systems and IIoT sensors via the CarbonEdge Edge Gateway.",
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          "Definitions",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        _buildBulletPoint("tCO2e: Tonnes of Carbon Dioxide Equivalent"),
        _buildBulletPoint("Scope 1: Direct emissions from owned sources"),
        _buildBulletPoint("Scope 2: Indirect emissions from purchased energy"),
      ],
    );
  }

  // HELPER WIDGETS
  pw.Widget _buildHeader(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.Divider(color: PdfColors.blue900),
      ],
    );
  }

  pw.Widget _buildBulletPoint(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("• ", style: const pw.TextStyle(fontSize: 12)),
          pw.Expanded(
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  pw.TableRow _buildTableRow(List<String> cells, {bool isHeader = false}) {
    return pw.TableRow(
      decoration: isHeader
          ? const pw.BoxDecoration(color: PdfColors.grey200)
          : null,
      children: cells.map((cell) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            cell,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildMetricRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildLegendItem(PdfColor color, String label) {
    return pw.Row(
      children: [
        pw.Container(width: 10, height: 10, color: color),
        pw.SizedBox(width: 5),
        pw.Text(label),
      ],
    );
  }

  Future<void> _exportExcel() async {
    try {
      var excel = excel_lib.Excel.createExcel();
      excel_lib.Sheet sheet = excel['ESG Report'];

      sheet.appendRow([
        excel_lib.TextCellValue('Month'),
        excel_lib.TextCellValue('Actual Emissions'),
        excel_lib.TextCellValue('Predicted'),
        excel_lib.TextCellValue('Target'),
      ]);
      for (var data in emissionsData) {
        sheet.appendRow([
          excel_lib.TextCellValue(data['month'].toString()),
          excel_lib.DoubleCellValue(data['actual'] as double),
          excel_lib.DoubleCellValue(data['predicted'] as double),
          excel_lib.DoubleCellValue(data['target'] as double),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        _showError("Failed to encode Excel file");
        return;
      }

      await FileExportHelper.saveAndOpenFile(
        bytes: Uint8List.fromList(bytes),
        fileName: 'ESG_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Excel file exported!")));
      }
    } catch (e) {
      _showError("Export failed: $e");
    }
  }

  Future<void> _exportCSV() async {
    try {
      List<List<dynamic>> rows = [
        ["Month", "Actual", "Predicted", "Target"],
        ...emissionsData.map(
          (e) => [e['month'], e['actual'], e['predicted'], e['target']],
        ),
      ];

      String csv = const ListToCsvConverter().convert(rows);
      final bytes = Uint8List.fromList(utf8.encode(csv));

      await FileExportHelper.saveAndOpenFile(
        bytes: bytes,
        fileName: 'emissions_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("CSV exported!")));
      }
    } catch (e) {
      _showError("CSV export failed: $e");
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}

class _ESGStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ESGStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.bar_chart, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
