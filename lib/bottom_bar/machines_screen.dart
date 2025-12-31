// import 'dart:async';
// import 'dart:math';
// import 'package:carbonedge/data/machine_data.dart';
// import 'package:carbonedge/theme/app_theme.dart';

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class MachinesScreen extends StatefulWidget {
//   const MachinesScreen({super.key});

//   @override
//   State<MachinesScreen> createState() => _MachinesScreenState();
// }

// class _MachinesScreenState extends State<MachinesScreen> {
//   // State
//   String _selectedMachine = MachineData.defaultMachine;
//   bool _isRunning = true;
//   double _targetTemp = 1450.0;
//   double _targetSpeed = 85.0;
//   double _targetFeed = 120.0;
  
//   // Simulation
//   late Timer _timer;
//   final Random _random = Random();
  
//   // Real-time values (simulated)
//   double _currentTemp = 1448.2;
//   double _currentSpeed = 84.8;
//   double _currentFeed = 119.5;
  
//   final List<String> _machines = MachineData.machines;

//   @override
//   void initState() {
//     super.initState();
//     _timer = Timer.periodic(const Duration(milliseconds: 800), _updateSimulation);
//   }

//   @override
//   void dispose() {
//     _timer.cancel();
//     super.dispose();
//   }

//   void _updateSimulation(Timer timer) {
//     if (!mounted) return;
//     setState(() {
//       if (_isRunning) {
//         // Drift towards target
//         _currentTemp += (_targetTemp - _currentTemp) * 0.1 + (_random.nextDouble() - 0.5) * 2;
//         _currentSpeed += (_targetSpeed - _currentSpeed) * 0.1 + (_random.nextDouble() - 0.5) * 0.5;
//         _currentFeed += (_targetFeed - _currentFeed) * 0.1 + (_random.nextDouble() - 0.5) * 1.0;
//       } else {
//         // Cool down / spin down
//         _currentTemp = max(25.0, _currentTemp * 0.995);
//         _currentSpeed = max(0.0, _currentSpeed * 0.95);
//         _currentFeed = 0.0;
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.background,
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           bool isWide = constraints.maxWidth > 1000;
          
//           if (isWide) {
//             return Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Left Sidebar: Machine List
//                 SizedBox(
//                   width: 280,
//                   child: _buildMachineList(),
//                 ),
//                 VerticalDivider(color: AppTheme.surfaceLight, width: 1),
//                 // Center: Controls & Graphs
//                 Expanded(
//                   flex: 5,
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(24),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildHeader(),
//                         const SizedBox(height: 24),
//                         _buildControlPanel(),
//                         const SizedBox(height: 24),
//                         _buildRealtimeMetrics(false),
//                       ],
//                     ),
//                   ),
//                 ),
//                 VerticalDivider(color: AppTheme.surfaceLight, width: 1),
//                 // Right: Diagnostics
//                 Expanded(
//                   flex: 3,
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(24),
//                     child: Column(
//                       children: [
//                         _buildComponentHealth(),
//                         const SizedBox(height: 24),
//                         _buildMaintenanceInfo(),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           } else {
//             // Mobile Layout
//             return SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   _buildMobileMachineSelector(),
//                   const SizedBox(height: 16),
//                   _buildHeader(),
//                   const SizedBox(height: 24),
//                   _buildControlPanel(),
//                   const SizedBox(height: 24),
//                   _buildRealtimeMetrics(true),
//                   const SizedBox(height: 24),
//                   _buildComponentHealth(),
//                   const SizedBox(height: 24),
//                   _buildMaintenanceInfo(),
//                 ],
//               ),
//             );
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildMachineList() {
//     return Container(
//       color: AppTheme.surface,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(24),
//             child: Text(
//               "ASSETS",
//               style: GoogleFonts.orbitron(
//                 color: AppTheme.textSecondary,
//                 fontSize: 12,
//                 letterSpacing: 1.5,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: _machines.length,
//               itemBuilder: (context, index) {
//                 final machine = _machines[index];
//                 final isSelected = machine == _selectedMachine;
//                 return InkWell(
//                   onTap: () => setState(() => _selectedMachine = machine),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//                     decoration: BoxDecoration(
//                       color: isSelected ? AppTheme.neonCyan.withOpacity(0.1) : null,
//                       border: isSelected 
//                         ? const Border(left: BorderSide(color: AppTheme.neonCyan, width: 3))
//                         : null,
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.precision_manufacturing,
//                           color: isSelected ? AppTheme.neonCyan : AppTheme.textSecondary,
//                           size: 20,
//                         ),
//                         const SizedBox(width: 12),
//                         Text(
//                           machine,
//                           style: GoogleFonts.inter(
//                             color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
//                             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                           ),
//                         ),
//                         const Spacer(),
//                         if (isSelected)
//                           const Icon(Icons.chevron_right, color: AppTheme.neonCyan, size: 16),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMobileMachineSelector() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: AppTheme.surface,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: AppTheme.surfaceLight),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: _selectedMachine,
//           isExpanded: true,
//           dropdownColor: AppTheme.surface,
//           icon: const Icon(Icons.expand_more, color: AppTheme.neonCyan),
//           items: _machines.map((m) => DropdownMenuItem(
//             value: m,
//             child: Text(m, style: const TextStyle(color: AppTheme.textPrimary)),
//           )).toList(),
//           onChanged: (val) => setState(() => _selectedMachine = val!),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               _selectedMachine.toUpperCase(),
//               style: GoogleFonts.orbitron(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: AppTheme.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Row(
//               children: [
//                 Container(
//                   width: 8,
//                   height: 8,
//                   decoration: BoxDecoration(
//                     color: _isRunning ? AppTheme.neonGreen : AppTheme.neonRed,
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: (_isRunning ? AppTheme.neonGreen : AppTheme.neonRed).withOpacity(0.5),
//                         blurRadius: 6,
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   _isRunning ? "OPERATIONAL" : "STOPPED",
//                   style: GoogleFonts.firaCode(
//                     color: _isRunning ? AppTheme.neonGreen : AppTheme.neonRed,
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: AppTheme.surface,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: AppTheme.surfaceLight),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 "OEE SCORE",
//                 style: GoogleFonts.inter(
//                   color: AppTheme.textSecondary,
//                   fontSize: 10,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 "87.4%",
//                 style: GoogleFonts.orbitron(
//                   color: AppTheme.neonCyan,
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildControlPanel() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: AppTheme.surface,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppTheme.surfaceLight),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 "CONTROL PANEL",
//                 style: GoogleFonts.orbitron(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: AppTheme.textPrimary,
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: AppTheme.surfaceLight,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   "MODE: AUTO",
//                   style: GoogleFonts.firaCode(
//                     fontSize: 12,
//                     color: AppTheme.neonCyan,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: _isRunning ? null : () => setState(() => _isRunning = true),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppTheme.neonGreen.withOpacity(0.2),
//                     foregroundColor: AppTheme.neonGreen,
//                     side: const BorderSide(color: AppTheme.neonGreen),
//                     padding: const EdgeInsets.symmetric(vertical: 20),
//                   ),
//                   child: const Text("START MACHINE"),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: !_isRunning ? null : () => setState(() => _isRunning = false),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppTheme.neonRed.withOpacity(0.2),
//                     foregroundColor: AppTheme.neonRed,
//                     side: const BorderSide(color: AppTheme.neonRed),
//                     padding: const EdgeInsets.symmetric(vertical: 20),
//                   ),
//                   child: const Text("STOP MACHINE"),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 32),
//           _buildSliderControl(
//             "TARGET TEMPERATURE",
//             _targetTemp,
//             1000,
//             1600,
//             "°C",
//             (val) => setState(() => _targetTemp = val),
//           ),
//           const SizedBox(height: 24),
//           _buildSliderControl(
//             "ROTATION SPEED",
//             _targetSpeed,
//             0,
//             120,
//             "RPM",
//             (val) => setState(() => _targetSpeed = val),
//           ),
//           const SizedBox(height: 24),
//           _buildSliderControl(
//             "FEED RATE",
//             _targetFeed,
//             0,
//             200,
//             "t/h",
//             (val) => setState(() => _targetFeed = val),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSliderControl(
//     String label,
//     double value,
//     double min,
//     double max,
//     String unit,
//     ValueChanged<double> onChanged,
//   ) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               label,
//               style: GoogleFonts.inter(
//                 color: AppTheme.textSecondary,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             Text(
//               "${value.toStringAsFixed(1)} $unit",
//               style: GoogleFonts.firaCode(
//                 color: AppTheme.neonCyan,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         SliderTheme(
//           data: SliderThemeData(
//             activeTrackColor: AppTheme.neonCyan,
//             inactiveTrackColor: AppTheme.surfaceLight,
//             thumbColor: AppTheme.neonCyan,
//             overlayColor: AppTheme.neonCyan.withOpacity(0.2),
//             trackHeight: 4,
//             thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
//           ),
//           child: Slider(
//             value: value,
//             min: min,
//             max: max,
//             onChanged: onChanged,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildRealtimeMetrics(bool isMobile) {
//     List<Widget> cards = [
//       _buildMetricCard(
//         "Temperature",
//         _currentTemp.toStringAsFixed(1),
//         "°C",
//         Icons.thermostat,
//         AppTheme.neonOrange,
//       ),
//       const SizedBox(width: 16, height: 16),
//       _buildMetricCard(
//         "Speed",
//         _currentSpeed.toStringAsFixed(1),
//         "RPM",
//         Icons.speed,
//         AppTheme.neonGreen,
//       ),
//       const SizedBox(width: 16, height: 16),
//       _buildMetricCard(
//         "Feed Rate",
//         _currentFeed.toStringAsFixed(1),
//         "t/h",
//         Icons.input,
//         AppTheme.neonPurple,
//       ),
//     ];

//     if (isMobile) {
//       return Column(children: cards);
//     }

//     return Row(
//       children: cards.map((c) => c is SizedBox ? c : Expanded(child: c)).toList(),
//     );
//   }

//   Widget _buildMetricCard(
//     String label,
//     String value,
//     String unit,
//     IconData icon,
//     Color color,
//   ) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppTheme.surface,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: color, size: 16),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   label.toUpperCase(),
//                   style: GoogleFonts.inter(
//                     color: AppTheme.textSecondary,
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           FittedBox(
//             fit: BoxFit.scaleDown,
//             alignment: Alignment.centerLeft,
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.baseline,
//               textBaseline: TextBaseline.alphabetic,
//               children: [
//                 Text(
//                   value,
//                   style: GoogleFonts.orbitron(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: AppTheme.textPrimary,
//                   ),
//                 ),
//                 const SizedBox(width: 4),
//                 Text(
//                   unit,
//                   style: GoogleFonts.inter(
//                     color: AppTheme.textSecondary,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildComponentHealth() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: AppTheme.surface,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppTheme.surfaceLight),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "COMPONENT HEALTH",
//             style: GoogleFonts.orbitron(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: AppTheme.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 24),
//           _buildHealthItem("Main Motor", 98, AppTheme.neonGreen),
//           const SizedBox(height: 16),
//           _buildHealthItem("Gearbox", 85, AppTheme.neonGreen),
//           const SizedBox(height: 16),
//           _buildHealthItem("Drive Bearing", 72, AppTheme.neonOrange),
//           const SizedBox(height: 16),
//           _buildHealthItem("Cooling Fan", 94, AppTheme.neonGreen),
//           const SizedBox(height: 16),
//           _buildHealthItem("Hydraulic Pump", 45, AppTheme.neonRed),
//         ],
//       ),
//     );
//   }

//   Widget _buildHealthItem(String name, int health, Color color) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               name,
//               style: GoogleFonts.inter(
//                 color: AppTheme.textPrimary,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             Text(
//               "$health%",
//               style: GoogleFonts.firaCode(
//                 color: color,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         ClipRRect(
//           borderRadius: BorderRadius.circular(4),
//           child: LinearProgressIndicator(
//             value: health / 100,
//             backgroundColor: AppTheme.surfaceLight,
//             valueColor: AlwaysStoppedAnimation<Color>(color),
//             minHeight: 6,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildMaintenanceInfo() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: AppTheme.surface,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppTheme.surfaceLight),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "MAINTENANCE LOG",
//             style: GoogleFonts.orbitron(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: AppTheme.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 24),
//           _buildLogItem("2023-10-15", "Oil Change", "Completed"),
//           Divider(color: AppTheme.surfaceLight, height: 32),
//           _buildLogItem("2023-11-02", "Bearing Inspection", "Completed"),
//           Divider(color: AppTheme.surfaceLight, height: 32),
//           _buildLogItem("2023-12-10", "Filter Replacement", "Scheduled", isUpcoming: true),
//         ],
//       ),
//     );
//   }

//   Widget _buildLogItem(String date, String task, String status, {bool isUpcoming = false}) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               date,
//               style: GoogleFonts.firaCode(
//                 color: AppTheme.textSecondary,
//                 fontSize: 12,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               task,
//               style: GoogleFonts.inter(
//                 color: AppTheme.textPrimary,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//         const Spacer(),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           decoration: BoxDecoration(
//             color: isUpcoming ? AppTheme.neonOrange.withOpacity(0.1) : AppTheme.neonGreen.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(4),
//             border: Border.all(
//               color: isUpcoming ? AppTheme.neonOrange : AppTheme.neonGreen,
//               width: 1,
//             ),
//           ),
//           child: Text(
//             status.toUpperCase(),
//             style: GoogleFonts.inter(
//               color: isUpcoming ? AppTheme.neonOrange : AppTheme.neonGreen,
//               fontSize: 10,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
