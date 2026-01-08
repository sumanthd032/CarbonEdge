import numpy as np
import pandas as pd
import random

def generate_kiln_dataset_high_anomaly(rows=10000, anomaly_rate=0.20):
    data = {}

    data["timestamp"] = pd.date_range(start="2024-01-01", periods=rows, freq="S")

    # Normal operational values
    data["kiln_temperature"] = np.random.normal(1450, 8, rows)
    data["secondary_air_temp"] = np.random.normal(900, 6, rows)
    data["kiln_pressure"] = np.random.normal(1.2, 0.05, rows)
    data["rotary_speed_rpm"] = np.random.normal(3.5, 0.1, rows)
    data["fuel_flow_rate"] = np.random.normal(250, 5, rows)
    data["primary_airflow"] = np.random.normal(50, 2, rows)
    data["secondary_airflow"] = np.random.normal(70, 3, rows)
    data["motor_current"] = np.random.normal(180, 4, rows)
    data["vibration_level"] = np.random.normal(2.5, 0.2, rows)
    data["exhaust_o2"] = np.random.normal(4, 0.2, rows)
    data["exhaust_co"] = np.random.normal(0.18, 0.05, rows)
    data["exhaust_co2"] = np.random.normal(26, 0.4, rows)
    data["feed_rate"] = np.random.normal(200, 4, rows)
    data["kiln_torque"] = np.random.normal(420, 10, rows)
    data["preheater_temp"] = np.random.normal(780, 10, rows)
    data["clinker_temp"] = np.random.normal(1250, 7, rows)

    df = pd.DataFrame(data)

    num_anomalies = int(rows * anomaly_rate)

    # Instead of isolated points → anomaly *clusters*
    anomaly_starts = np.random.choice(rows - 10, num_anomalies, replace=False)

    for start in anomaly_starts:
        length = random.randint(3, 10)  # 3–10 sec anomaly burst
        end = min(start + length, rows - 1)

        failure_type = random.choice([
            "overheat_spike",
            "airflow_failure",
            "fuel_pressure_spike",
            "vibration_shock",
            "exhaust_gas_leak"
        ])

        for idx in range(start, end):

            if failure_type == "overheat_spike":
                df.loc[idx, "kiln_temperature"] += np.random.uniform(40, 80)
                df.loc[idx, "kiln_pressure"] += np.random.uniform(0.3, 0.7)
                df.loc[idx, "motor_current"] += np.random.uniform(10, 20)

            elif failure_type == "airflow_failure":
                df.loc[idx, "primary_airflow"] += np.random.uniform(-20, -10)
                df.loc[idx, "secondary_airflow"] += np.random.uniform(-25, -12)
                df.loc[idx, "exhaust_o2"] += np.random.uniform(1, 2)

            elif failure_type == "fuel_pressure_spike":
                df.loc[idx, "fuel_flow_rate"] += np.random.uniform(40, 80)
                df.loc[idx, "kiln_temperature"] += np.random.uniform(20, 40)
                df.loc[idx, "exhaust_co"] += np.random.uniform(0.3, 0.6)

            elif failure_type == "vibration_shock":
                df.loc[idx, "vibration_level"] += np.random.uniform(4, 8)
                df.loc[idx, "kiln_torque"] += np.random.uniform(30, 50)
                df.loc[idx, "motor_current"] += np.random.uniform(15, 25)

            elif failure_type == "exhaust_gas_leak":
                df.loc[idx, "exhaust_co2"] += np.random.uniform(3, 6)
                df.loc[idx, "exhaust_co"] += np.random.uniform(0.4, 0.8)
                df.loc[idx, "secondary_air_temp"] += np.random.uniform(15, 30)

    return df


df = generate_kiln_dataset_high_anomaly(rows=10000, anomaly_rate=0.10)
df.to_csv("anomaly.csv", index=False)

print("Moderate-anomaly dataset created → anomaly.csv")
