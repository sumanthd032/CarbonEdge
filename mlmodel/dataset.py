import numpy as np
import pandas as pd


def generate_kiln_dataset(rows=10000, anomaly_rate=0.01):
    data = {}

    
    data["timestamp"] = pd.date_range(start="2025-12-02", periods=rows, freq="S")


    data["kiln_temperature"] = np.random.normal(1450, 8, rows)     # °C
    data["secondary_air_temp"] = np.random.normal(900, 6, rows)
    data["kiln_pressure"] = np.random.normal(1.2, 0.05, rows)      # bar
    data["rotary_speed_rpm"] = np.random.normal(3.5, 0.1, rows)    # rpm
    data["fuel_flow_rate"] = np.random.normal(250, 5, rows)        # kg/hr
    data["primary_airflow"] = np.random.normal(50, 2, rows)        # m3/s
    data["secondary_airflow"] = np.random.normal(70, 3, rows)
    data["motor_current"] = np.random.normal(180, 4, rows)         # amps
    data["vibration_level"] = np.random.normal(2.5, 0.2, rows)     # mm/s
    data["exhaust_o2"] = np.random.normal(4, 0.2, rows)            # %
    data["exhaust_co"] = np.random.normal(0.18, 0.05, rows)        # %
    data["exhaust_co2"] = np.random.normal(26, 0.4, rows)          # %
    data["feed_rate"] = np.random.normal(200, 4, rows)             # tons/hr
    data["kiln_torque"] = np.random.normal(420, 10, rows)          # kN
    data["preheater_temp"] = np.random.normal(780, 10, rows)       # °C
    data["clinker_temp"] = np.random.normal(1250, 7, rows)

    df = pd.DataFrame(data)

    num_anomalies = int(rows * anomaly_rate)
    anomaly_indices = np.random.choice(rows, num_anomalies, replace=False)

    for idx in anomaly_indices:
        df.loc[idx, "kiln_temperature"] += np.random.uniform(20, 40)

        df.loc[idx, "secondary_airflow"] += np.random.uniform(-10, 15)
        df.loc[idx, "primary_airflow"] += np.random.uniform(-5, 8)

        df.loc[idx, "fuel_flow_rate"] += np.random.uniform(20, 40)

        df.loc[idx, "kiln_pressure"] += np.random.uniform(0.2, 0.5)

        df.loc[idx, "vibration_level"] += np.random.uniform(2, 5)

        df.loc[idx, "exhaust_co2"] += np.random.uniform(2, 4)
        df.loc[idx, "exhaust_co"] += np.random.uniform(0.2, 0.4)

    return df


df = generate_kiln_dataset(rows=10000, anomaly_rate=0.005)
df.to_csv("normal_dataset.csv", index=False)

print("Dataset created → normal_dataset.csv")
