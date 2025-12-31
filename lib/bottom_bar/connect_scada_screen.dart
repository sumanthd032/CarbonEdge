import 'dart:async';
import 'dart:math';

import 'package:carbonedge/data/machine_data.dart';
import 'package:carbonedge/theme/app_theme.dart';
import 'package:carbonedge/widgets/neon_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConnectScadaScreen extends StatefulWidget {
  const ConnectScadaScreen({super.key});

  @override
  State<ConnectScadaScreen> createState() => _ConnectScadaScreenState();
}

class _ConnectScadaScreenState extends State<ConnectScadaScreen>
    with TickerProviderStateMixin {
  String _selectedProtocol = "OPC-UA";
  bool _isConnected = false;
  bool _isConnecting = false;
  List<String> _connectionLogs = [];
  final ScrollController _logScrollController = ScrollController();

  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _discoveryController;

  // Live Data
  Timer? _dataTimer;
  int _latency = 0;
  double _dataRate = 0.0;
  int _activeTags = 0;
  int _discoveredMachines = 0;

  // Form Controllers
  final _opcUrlController = TextEditingController(
    text: "opc.tcp://192.168.100.21:4840",
  );
  String _opcSecurityMode = "Sign & Encrypt";

  final _mqttBrokerController = TextEditingController(
    text: "mqtt://192.168.100.50:1883",
  );
  final _mqttTopicController = TextEditingController(
    text: "/plant1/kiln1/data",
  );
  final _mqttClientIdController = TextEditingController(
    text: "carbonedge_sim_01",
  );
  String _mqttQos = "1";

  final _modbusIpController = TextEditingController(text: "192.168.100.90");
  final _modbusPortController = TextEditingController(text: "502");
  final _modbusSlaveIdController = TextEditingController(text: "1");

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _discoveryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _discoveryController.dispose();
    _dataTimer?.cancel();
    _opcUrlController.dispose();
    _mqttBrokerController.dispose();
    _mqttTopicController.dispose();
    _mqttClientIdController.dispose();
    _modbusIpController.dispose();
    _modbusPortController.dispose();
    _modbusSlaveIdController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _toggleConnection() {
    if (!_isConnected) {
      _startConnectionSequence();
    } else {
      _disconnect();
    }
  }

  void _startConnectionSequence() async {
    setState(() {
      _isConnecting = true;
      _connectionLogs = ["Initializing connection sequence..."];
    });

    final steps = [
      "Establishing secure handshake...",
      "Handshake initiated...",
      "Reading server nodes...",
      "Fetching machine registry...",
      "Syncing tags...",
      "Connection established.",
    ];

    for (var step in steps) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _connectionLogs.add(step);
      });
      _scrollToBottom();
    }

    if (!mounted) return;
    setState(() {
      _isConnected = true;
      _isConnecting = false;
      _discoveredMachines = 4; // Simulated count
    });
    _discoveryController.forward();
    _startLiveDataSimulation();
  }

  void _disconnect() {
    setState(() {
      _isConnected = false;
      _connectionLogs.clear();
      _activeTags = 0;
      _dataRate = 0.0;
      _latency = 0;
      _discoveredMachines = 0;
    });
    _discoveryController.reset();
    _dataTimer?.cancel();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startLiveDataSimulation() {
    _dataTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _latency = 12 + Random().nextInt(8); // 12-20ms
        _dataRate = 1.0 + Random().nextDouble() * 0.4; // 1.0-1.4 MB/s
        _activeTags = 238 + Random().nextInt(5); // Fluctuate slightly
      });
    });
  }

  void _showTagBrowser(String machineName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTagBrowserModal(machineName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildStickyHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 900;
                if (isWide) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Controls
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTechCard(_buildProtocolSelection()),
                              const SizedBox(height: 24),
                              _buildConnectionForm(),
                              const SizedBox(height: 24),
                              _buildNetworkDiagnostics(),
                              const SizedBox(height: 24),
                              _buildSavedGateways(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column: Visualization & Status
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _buildStatusCard(),
                              if (_isConnecting || _isConnected) ...[
                                const SizedBox(height: 24),
                                _buildConnectionTerminal(),
                              ],
                              const SizedBox(height: 24),
                              _buildDigitalTwinMap(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Mobile / Narrow Layout
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTechCard(_buildProtocolSelection()),
                        const SizedBox(height: 24),
                        _buildConnectionForm(),
                        const SizedBox(height: 24),
                        _buildNetworkDiagnostics(),
                        const SizedBox(height: 24),
                        _buildSavedGateways(),
                        if (_isConnecting || _isConnected) ...[
                          const SizedBox(height: 24),
                          _buildConnectionTerminal(),
                        ],
                        const SizedBox(height: 24),
                        _buildStatusCard(),
                        const SizedBox(height: 24),
                        _buildDigitalTwinMap(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0F16), Color(0xFF0D111A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceLight, width: 1),
        ),
      ),
      child: Center(
        child: Text(
          "Connect SCADA",
          style: GoogleFonts.orbitron(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.neonAqua,
            shadows: [
              Shadow(
                color: AppTheme.neonAqua.withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechCard(Widget child) {
    return CustomPaint(
      painter: TechCornerPainter(
        color: AppTheme.neonAqua.withValues(alpha: 0.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildProtocolSelection() {
    return Row(
      children: [
        _buildProtocolTab("OPC-UA"),
        const SizedBox(width: 16),
        _buildProtocolTab("MQTT"),
        const SizedBox(width: 16),
        _buildProtocolTab("Modbus TCP"),
      ],
    );
  }

  Widget _buildProtocolTab(String label) {
    final isSelected = _selectedProtocol == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedProtocol = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.neonAqua : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? AppTheme.neonAqua : Colors.transparent,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.neonAqua.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.black : AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionForm() {
    return NeonCard(
      borderRadius: 20,
      borderColor: Colors.teal.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedProtocol == "OPC-UA") ...[
            _buildTextField(
              "Server URL",
              "opc.tcp://192.168.100.21:4840",
              _opcUrlController,
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              "Security Mode",
              ["None", "Sign", "Sign & Encrypt"],
              _opcSecurityMode,
              (val) {
                setState(() {
                  _opcSecurityMode = val!;
                });
              },
            ),
          ] else if (_selectedProtocol == "MQTT") ...[
            _buildTextField(
              "Broker URL",
              "mqtt://192.168.100.50:1883",
              _mqttBrokerController,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              "Topic",
              "/plant1/kiln1/data",
              _mqttTopicController,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              "Client ID",
              "carbonedge_sim_01",
              _mqttClientIdController,
            ),
            const SizedBox(height: 16),
            _buildDropdownField("QoS", ["0", "1", "2"], _mqttQos, (val) {
              setState(() {
                _mqttQos = val!;
              });
            }),
          ] else if (_selectedProtocol == "Modbus TCP") ...[
            _buildTextField(
              "IP Address",
              "192.168.100.90",
              _modbusIpController,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField("Port", "502", _modbusPortController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    "Slave ID",
                    "1",
                    _modbusSlaveIdController,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isConnecting ? null : _toggleConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonAqua,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                shadowColor: AppTheme.neonAqua.withValues(alpha: 0.5),
              ),
              child: _isConnecting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      _isConnected ? "Disconnect" : "Connect to Gateway",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionTerminal() {
    return NeonCard(
      borderRadius: 12,
      borderColor: AppTheme.neonAqua.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.black,
          border: const Border(
            left: BorderSide(color: AppTheme.neonAqua, width: 4),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(12),
        child: ListView.builder(
          controller: _logScrollController,
          itemCount: _connectionLogs.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                "> ${_connectionLogs[index]}",
                style: GoogleFonts.firaCode(
                  color: AppTheme.neonAqua,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return NeonCard(
      borderRadius: 20,
      glow: _isConnected,
      borderColor: _isConnected ? AppTheme.neonGreen : Colors.grey,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isConnected ? AppTheme.neonGreen : Colors.grey,
                  boxShadow: _isConnected
                      ? [
                          const BoxShadow(
                            color: AppTheme.neonGreen,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _isConnected ? "Connected" : "Not Connected",
                style: GoogleFonts.inter(
                  color: _isConnected ? AppTheme.neonGreen : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isConnected)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatItem("Latency", "${_latency}ms"),
                      const SizedBox(height: 16),
                      _buildStatItem(
                        "Data Rate",
                        "${_dataRate.toStringAsFixed(1)} MB/s",
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatItem("Active Tags", "$_activeTags"),
                      const SizedBox(height: 16),
                      _buildStatItem("Last Sync", "Just now"),
                    ],
                  ),
                ),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "Connect to a gateway to view live statistics.",
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDigitalTwinMap() {
    return NeonCard(
      borderRadius: 20,
      borderColor: AppTheme.neonAqua,
      glow: _isConnected,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Plant Map",
                style: GoogleFonts.orbitron(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neonAqua.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.neonAqua),
                  ),
                  child: Text(
                    "LIVE",
                    style: GoogleFonts.inter(
                      color: AppTheme.neonAqua,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF05080D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.neonAqua.withValues(alpha: 0.3),
              ),
            ),
            child: Stack(
              children: [
                // Grid Background
                Positioned.fill(
                  child: GridPaper(
                    color: AppTheme.neonAqua.withValues(alpha: 0.05),
                    divisions: 2,
                    subdivisions: 4,
                  ),
                ),
                // Nodes and Links
                // Central Gateway
                Align(
                  alignment: Alignment.center,
                  child: _buildMapNode(Icons.router, "Gateway", true),
                ),
                // Machines - Radial Layout
                if (_isConnected) ...[
                  // Top Left
                  Align(
                    alignment: const Alignment(-0.65, -0.65),
                    child: _buildMachineNode(MachineData.machines[0], "145°C", "0.59g", 0),
                  ),
                  // Top Right
                  Align(
                    alignment: const Alignment(0.65, -0.65),
                    child: _buildMachineNode(MachineData.machines[1], "142°C", "0.45g", 1),
                  ),
                  // Bottom Left
                  Align(
                    alignment: const Alignment(-0.65, 0.65),
                    child: _buildMachineNode("Fan 3", "850rpm", "0.12g", 2),
                  ),
                  // Bottom Right
                  Align(
                    alignment: const Alignment(0.65, 0.65),
                    child: _buildMachineNode("Power", "480V", "81%", 3),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_isConnected)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildInfoChip("Machines Discovered", "$_discoveredMachines"),
                _buildInfoChip("Tags Detected", "$_activeTags"),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMapNode(IconData icon, String label, bool isCentral) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isCentral ? 16 : 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: _isConnected ? AppTheme.neonAqua : Colors.grey,
              width: 2,
            ),
            boxShadow: _isConnected
                ? [
                    BoxShadow(
                      color: AppTheme.neonAqua.withValues(alpha: 0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            icon,
            color: _isConnected ? AppTheme.neonAqua : Colors.grey,
            size: isCentral ? 32 : 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMachineNode(String name, String val1, String val2, int index) {
    return FadeTransition(
      opacity: _discoveryController,
      child: GestureDetector(
        onTap: () => _showTagBrowser(name),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.neonCyan),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonCyan.withValues(
                          alpha: 0.3 + (_pulseController.value * 0.3),
                        ),
                        blurRadius: 10 + (_pulseController.value * 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.factory,
                    color: AppTheme.neonCyan,
                    size: 24,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      color: AppTheme.neonCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$val1 | $val2",
                    style: GoogleFonts.firaCode(
                      color: Colors.white,
                      fontSize: 9,
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

  Widget _buildTagBrowserModal(String machineName) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.neonAqua),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.surfaceLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Discovered Tags: $machineName",
                  style: GoogleFonts.orbitron(
                    color: AppTheme.neonAqua,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTagItem("$machineName.temperature", "145.2", "FLOAT"),
                _buildTagItem("$machineName.vibration", "0.59", "FLOAT"),
                _buildTagItem("$machineName.status", "RUNNING", "BOOL"),
                _buildTagItem("$machineName.load", "81", "INT"),
                _buildTagItem("$machineName.power", "480", "INT"),
                _buildTagItem("$machineName.efficiency", "92.5", "FLOAT"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagItem(String tag, String value, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tag,
                style: GoogleFonts.firaCode(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                ),
              ),
              Text(
                type,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.firaCode(
              color: AppTheme.neonCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String placeholder,
    TextEditingController controller, {
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
            ),
            filled: true,
            fillColor: AppTheme.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.neonAqua, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.surfaceLight,
              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.neonAqua),
              style: const TextStyle(color: AppTheme.textPrimary),
              items: items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkDiagnostics() {
    return _buildTechCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Network Diagnostics",
            style: GoogleFonts.orbitron(
              color: AppTheme.neonAqua,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDiagItem("Ping", "${24 + Random().nextInt(10)}ms", Icons.network_check),
              _buildDiagItem("Signal", "-42dBm", Icons.wifi),
              _buildDiagItem("Security", "TLS 1.2", Icons.security),
            ],
          ),
          const SizedBox(height: 12),
          // Animated Bar
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.85,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonGreen.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.firaCode(
            color: AppTheme.neonAqua,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSavedGateways() {
    final gateways = [
      {"name": "Kiln Main PLC", "ip": "192.168.100.21"},
      {"name": "Packaging Unit B", "ip": "192.168.100.45"},
      {"name": "Cooling Tower", "ip": "192.168.100.88"},
    ];

    return _buildTechCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Saved Gateways",
            style: GoogleFonts.orbitron(
              color: AppTheme.neonAqua,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...gateways.map((g) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.surfaceLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g["name"]!,
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      g["ip"]!,
                      style: GoogleFonts.firaCode(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios, color: AppTheme.neonAqua, size: 14),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppTheme.neonAqua,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class GridBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  GridBackgroundPainter({required this.animation, required this.color})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final double spacing = 40;
    final double offset = animation.value * spacing;

    // Vertical Lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal Lines (Moving)
    for (double y = offset - spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Random "Data" blips
    final random = Random(42); // Fixed seed for consistent pattern
    final blipPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
      
    for(int i=0; i<20; i++) {
       double x = (random.nextInt(size.width ~/ spacing) * spacing).toDouble();
       double y = ((random.nextInt(size.height ~/ spacing) * spacing) + offset).toDouble() % size.height;
       canvas.drawRect(Rect.fromLTWH(x + 2, y + 2, spacing - 4, spacing - 4), blipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GridBackgroundPainter oldDelegate) => true;
}

class TechCornerPainter extends CustomPainter {
  final Color color;
  final double length;
  final double thickness;

  TechCornerPainter({
    required this.color,
    this.length = 20,
    this.thickness = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Top Left
    path.moveTo(0, length);
    path.lineTo(0, 0);
    path.lineTo(length, 0);

    // Top Right
    path.moveTo(size.width - length, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, length);

    // Bottom Right
    path.moveTo(size.width, size.height - length);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - length, size.height);

    // Bottom Left
    path.moveTo(length, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height - length);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
