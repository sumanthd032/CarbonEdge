# simulate_stream.py
# Usage: python simulate_stream.py --csv kiln_dataset.csv --speed normal

import requests
import time
import csv
import argparse
from pprint import pprint
from termcolor import colored

URL = "http://localhost:8000/ingest"

# Severity → Color mapping
SEVERITY_COLORS = {
    'normal': 'green',
    'warning': 'yellow',
    'high': 'red',
    'critical': 'magenta'
}


def print_section(title, color='cyan'):
    """Print formatted section header"""
    print("\n" + colored("=" * 80, color))
    print(colored(f"  {title}", color, attrs=['bold']))
    print(colored("=" * 80, color))


def print_data_sent(timestamp, sensor_values):
    """Print clean summary of data being sent"""
    print_section("📤 DATA SENT TO BACKEND", 'cyan')

    print(f"⏰ Timestamp: {colored(timestamp, 'white', attrs=['bold'])}")
    print(f"📊 Total Sensors: {colored(len(sensor_values), 'white', attrs=['bold'])}")

    print("\n🔍 Sensor Values (first 5):")
    for i, (key, value) in enumerate(list(sensor_values.items())[:5]):
        print(f"   {i+1}. {key}: {value:.4f}")

    if len(sensor_values) > 5:
        print(f"   ... and {len(sensor_values) - 5} more sensors")


def print_response(response):
    """Print formatted API response based on NEW app.py JSON format"""
    print_section("🤖 AI PREDICTION RECEIVED", 'blue')

    # -------- RAW JSON SECTION (Flutter JSON Preview) --------
    print("\n" + "="*80)
    print(colored("📦 RAW JSON RECEIVED (Flutter will parse this)", "magenta", attrs=['bold']))
    print("="*80)
    pprint(response)
    print("="*80 + "\n")

    # Basic info
    print(f"Plant ID: {response.get('plant_id', 'N/A')}")
    print(f"Timestamp: {response.get('timestamp', 'N/A')}")

    buffer_len = response.get("buffer_len", 0)
    print(f"Buffer Fill: {buffer_len}/{buffer_len}")

    # If prediction isn't ready yet
    if not response.get("buffer_filled", False):
        print(colored("\n⏳ Buffering data... prediction pending", 'yellow'))
        return

    # Extract main fields
    severity = response.get("severity", "normal")
    severity_color = SEVERITY_COLORS.get(severity, "white")

    anomaly_score = response.get("anomaly_score", 0)
    confidence = response.get("confidence", 0)
    stability = response.get("stability", 0)
    rolling_avg = response.get("rolling_avg", 0)
    rolling_std = response.get("rolling_std", 0)

    # -------- ANOMALY METRICS --------
    print(f"\n{'─' * 80}")
    print(colored("📈 ANOMALY METRICS", 'white', attrs=['bold']))
    print(f"{'─' * 80}")

    print(f"Anomaly Score: {colored(f'{anomaly_score:.4f}', severity_color, attrs=['bold'])}")
    print(f"Severity: {colored(severity.upper(), severity_color, attrs=['bold'])}")
    print(f"Confidence: {confidence:.2f}%")

    # -------- ROLLING STATS --------
    print(f"\n{'─' * 80}")
    print(colored("📊 ROLLING STATISTICS", 'white', attrs=['bold']))
    print(f"{'─' * 80}")

    print(f"Rolling Average: {rolling_avg:.4f}")
    print(f"Rolling Std Dev: {rolling_std:.4f}")
    print(f"Stability: {stability:.2f}%")

    # -------- TOP CAUSES --------
    top_causes = response.get("top_causes", [])
    if top_causes:
        print(f"\n{'─' * 80}")
        print(colored("🔥 TOP CONTRIBUTING SENSORS", 'white', attrs=['bold']))
        print(f"{'─' * 80}")
        for i, item in enumerate(top_causes, 1):
            print(f"{i}. {colored(item['sensor'], 'yellow')}: {item['impact']:.4f}")

    # -------- AI ANALYSIS --------
    print(f"\n{'─' * 80}")
    print(colored("🧠 AI ANALYSIS", 'white', attrs=['bold']))
    print(f"{'─' * 80}")

    print("\n🔍 Root Cause:")
    print(f"   {colored(response.get('root_cause', 'N/A'), 'cyan')}")

    print("\n💡 Recommendation:")
    print(f"   {colored(response.get('recommendation', 'N/A'), severity_color, attrs=['bold'])}")



def main(args):
    # Header
    print(colored("\n" + "=" * 80, 'magenta', attrs=['bold']))
    print(colored("   🚀 CarbonEdge AI - Real-Time Anomaly Detection Stream", 'magenta', attrs=['bold']))
    print(colored("=" * 80 + "\n", 'magenta', attrs=['bold']))

    # Speed config
    speed_map = {'fast': 0.1, 'normal': 1.0, 'slow': 2.0}
    delay = speed_map.get(args.speed, 1.0)

    print(f"📡 Backend URL: {colored(URL, 'green', attrs=['bold'])}")
    print(f"⚡ Speed: {colored(args.speed.upper(), 'yellow', attrs=['bold'])} ({delay}s delay)")
    print(f"📂 Dataset: {colored(args.csv, 'white')}\n")

    # Backend health check
    try:
        health = requests.get("http://localhost:8000/health", timeout=2)
        if health.status_code == 200:
            print(colored("✅ Backend connection successful\n", 'green'))
        else:
            print(colored("⚠️ Backend responded with issues\n", 'yellow'))
    except:
        print(colored("❌ Backend not reachable. Start with: uvicorn app:app --reload\n", 'red'))
        return

    # Stream rows
    row_count = 0

    try:
        with open(args.csv) as f:
            reader = csv.DictReader(f)

            for row in reader:
                row_count += 1

                timestamp = row.get("timestamp", "")
                sensor_values = {k: float(v) for k, v in row.items() if k != "timestamp"}

                # Print outgoing data
                print_data_sent(timestamp, sensor_values)

                payload = {
                    "plant_id": "plant_1",
                    "timestamp": timestamp,
                    "values": sensor_values
                }

                try:
                    r = requests.post(URL, json=payload, timeout=5)
                    r.raise_for_status()
                    response = r.json()
                    print_response(response)

                except Exception as e:
                    print(colored(f"\n❌ Request failed: {e}", 'red'))
                    print(colored("Retrying in 2 seconds...", 'yellow'))
                    time.sleep(2)
                    continue

                # Next datapoint delay
                print(colored(f"\n⏳ Waiting {delay}s before next datapoint...", 'white'))
                time.sleep(delay)

    except KeyboardInterrupt:
        print(colored("\n⚠️ Stream stopped by user", 'yellow'))
    except FileNotFoundError:
        print(colored(f"\n❌ File not found: {args.csv}", 'red'))
    finally:
        print(colored("\n" + "=" * 80, 'magenta', attrs=['bold']))
        print(colored(f"   📊 Stream Complete - Processed {row_count} rows", 'magenta', attrs=['bold']))
        print(colored("=" * 80 + "\n", 'magenta', attrs=['bold']))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Simulate real-time sensor data streaming")
    parser.add_argument("--csv", default="kiln_dataset.csv", help="CSV file to stream")
    parser.add_argument("--speed", choices=["fast", "normal", "slow"], default="normal", help="Stream speed")
    args = parser.parse_args()

    main(args)
