import 'dart:math';

class MachineSimulationService {
  static final Random _random = Random();

  static Map<String, dynamic> getKilnData() {
    return {
      "kiln_temperature": 1400 + _random.nextDouble() * 50, // 1400-1450 °C
      "secondary_air_temp": 800 + _random.nextDouble() * 30, // 800-830 °C
      "kiln_pressure": -1.5 + _random.nextDouble() * 0.5, // -1.5 to -1.0 mbar
      "rotary_speed_rpm": 3.5 + _random.nextDouble() * 0.2, // 3.5-3.7 rpm
      "fuel_flow_rate": 4500 + _random.nextDouble() * 100, // 4500-4600 kg/h
      "primary_airflow": 12000 + _random.nextDouble() * 500, // 12000-12500 m3/h
      "secondary_airflow": 25000 + _random.nextDouble() * 1000, // 25000-26000 m3/h
      "motor_current": 450 + _random.nextDouble() * 20, // 450-470 A
      "vibration_level": 2.0 + _random.nextDouble() * 0.5, // 2.0-2.5 mm/s
      "exhaust_o2": 2.5 + _random.nextDouble() * 0.5, // 2.5-3.0 %
      "exhaust_co": 150 + _random.nextDouble() * 50, // 150-200 ppm
      "exhaust_co2": 22 + _random.nextDouble() * 2, // 22-24 %
      "feed_rate": 280 + _random.nextDouble() * 10, // 280-290 t/h
      "kiln_torque": 60 + _random.nextDouble() * 5, // 60-65 %
      "preheater_temp": 950 + _random.nextDouble() * 20, // 950-970 °C
      "clinker_temp": 120 + _random.nextDouble() * 10, // 120-130 °C
    };
  }
}
