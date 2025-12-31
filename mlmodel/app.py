# app.py
# Usage: uvicorn app:app --reload --host 0.0.0.0 --port 8000

import asyncio
import uvicorn
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
import numpy as np
import joblib
import json
import os
from collections import deque
import tensorflow as tf
from typing import List, Dict

MODEL_DIR = 'carbonedge_model'

# -------------------------------------------------
# GLOBAL CONFIG
# -------------------------------------------------
SEQUENCE_BUFFER = 60  # Keep last 60 rows for sequence building
ROLLING_WINDOW = 30   # Rolling window for statistics

# -------------------------------------------------

app = FastAPI(title="CarbonEdge AI Realtime API")

# Load model, scaler, meta
if not os.path.exists(MODEL_DIR):
    raise RuntimeError("Model directory not found. Run train_model.py first.")

print("Loading model and artifacts...")
ae = tf.keras.models.load_model(os.path.join(MODEL_DIR, 'ae_model'))
scaler = joblib.load(os.path.join(MODEL_DIR, 'scaler.pkl'))

with open(os.path.join(MODEL_DIR, 'meta.json')) as f:
    meta = json.load(f)

COLUMNS = meta['columns']
SEQ_LEN = meta['seq_len']
THRESHOLD = meta['threshold']

# Sliding buffers per plant
buffers = {'plant_1': deque(maxlen=SEQUENCE_BUFFER)}
anomaly_history = {'plant_1': deque(maxlen=ROLLING_WINDOW)}

# ---------------- WebSocket Manager ----------------

class ConnectionManager:
    def __init__(self):
        self.active: List[WebSocket] = []
    
    async def connect(self, ws: WebSocket):
        await ws.accept()
        self.active.append(ws)
    
    def disconnect(self, ws: WebSocket):
        if ws in self.active:
            self.active.remove(ws)
    
    async def broadcast(self, message: dict):
        alive = []
        for ws in list(self.active):
            try:
                await ws.send_json(message)
                alive.append(ws)
            except Exception as e:
                print(f"WebSocket send error: {e}")
        self.active = alive

manager = ConnectionManager()

# ---------------- Data Models ----------------

class SensorRow(BaseModel):
    plant_id: str = "plant_1"
    timestamp: str
    values: Dict[str, float]

# ---------------- Helper Functions ----------------

def preprocess_row(values_dict):
    """Convert sensor dict to scaled numpy array"""
    try:
        row = [float(values_dict.get(c, 0.0)) for c in COLUMNS]
        row = np.array(row).reshape(1, -1)
        row_scaled = scaler.transform(row)
        return row_scaled.flatten()
    except Exception as e:
        print(f"Preprocessing error: {e}")
        raise

def sequence_from_buffer(buf):
    """Build sequence with zero-padding if needed"""
    try:
        arr = np.array(list(buf))
        
        if arr.shape[0] < SEQ_LEN:
            # Pad with zeros at the beginning
            pad_rows = SEQ_LEN - arr.shape[0]
            pad = np.zeros((pad_rows, arr.shape[1]))
            arr = np.vstack([pad, arr])
        elif arr.shape[0] > SEQ_LEN:
            # Take last SEQ_LEN rows
            arr = arr[-SEQ_LEN:]
        
        return arr.reshape(1, SEQ_LEN, arr.shape[1])
    except Exception as e:
        print(f"Sequence building error: {e}")
        raise

def compute_reconstruction_error(seq):
    """Calculate reconstruction error from autoencoder"""
    try:
        pred = ae.predict(seq, verbose=0)
        mse = np.mean(np.square(pred - seq))
        feature_errors = np.mean(np.square(pred - seq), axis=1)[0]
        return float(mse), feature_errors
    except Exception as e:
        print(f"Reconstruction error calculation failed: {e}")
        raise

def get_top_contributing_sensors(feature_errors, top_k=3):
    """Get sensors with highest reconstruction errors"""
    try:
        indices = np.argsort(feature_errors)[::-1][:top_k]
        return [
            {"sensor": COLUMNS[idx], "error": float(feature_errors[idx])}
            for idx in indices
        ]
    except Exception as e:
        print(f"Top sensors calculation error: {e}")
        return []

def compute_rolling_stats(history):
    """Calculate mean and std from rolling history"""
    if len(history) == 0:
        return 0.0, 0.0
    arr = np.array(list(history))
    return float(np.mean(arr)), float(np.std(arr))

def calculate_severity(anomaly_score, rolling_avg):
    """Determine severity level"""
    if anomaly_score < 1.0:
        return "normal"
    elif anomaly_score < 1.5:
        return "warning"
    elif anomaly_score < 2.5:
        return "high"
    else:
        return "critical"

def calculate_confidence(rolling_std, history_len):
    """Calculate prediction confidence based on stability and data availability"""
    # Lower confidence when we have less historical data
    data_confidence = min(history_len / ROLLING_WINDOW, 1.0)
    # Lower confidence when standard deviation is high
    stability_confidence = 1.0 / (1.0 + rolling_std)
    return float(data_confidence * stability_confidence)

def calculate_stability_score(rolling_std):
    """Calculate system stability (0-100)"""
    normalized = min(rolling_std, 1.0)
    return float((1.0 - normalized) * 100)

def determine_root_cause(top_sensors):
    """Analyze top sensors to determine root cause"""
    if not top_sensors:
        return "No anomaly detected"
    
    top_sensor = top_sensors[0]['sensor'].lower()
    
    if 'temp' in top_sensor:
        return "Temperature anomaly - airflow or combustion issue"
    elif 'vibration' in top_sensor:
        return "Vibration anomaly - mechanical wear or imbalance"
    elif 'pressure' in top_sensor:
        return "Pressure anomaly - blockage or flow restriction"
    elif 'speed' in top_sensor or 'rpm' in top_sensor:
        return "Speed variation - drive system irregularity"
    elif 'current' in top_sensor:
        return "Electrical anomaly - load imbalance"
    else:
        return f"Anomaly detected in {top_sensor}"

def generate_recommendation(severity, top_sensors, root_cause):
    """Generate actionable recommendation"""
    if severity == "critical":
        return "CRITICAL: Initiate controlled shutdown and inspect immediately."
    
    if severity == "normal":
        return "System operating normally"
    
    if not top_sensors:
        return "Monitor system performance"
    
    top_sensor = top_sensors[0]['sensor'].lower()
    
    if 'temp' in top_sensor:
        return "Adjust airflow by 2–3% and check fan alignment."
    elif 'vibration' in top_sensor:
        return "Inspect bearings and alignment within 12 hours."
    elif 'pressure' in top_sensor:
        return "Check filters and cyclone systems for blockage."
    elif 'speed' in top_sensor or 'rpm' in top_sensor:
        return "Verify motor controller and inspect coupling."
    elif 'current' in top_sensor:
        return "Balance electrical loads across phases."
    else:
        return f"Monitor {top_sensors[0]['sensor']} closely."

# ---------------- Ingest Endpoint ----------------

@app.post("/ingest")
async def ingest(row: SensorRow):
    """Real-time ingestion and prediction endpoint"""
    try:
        plant = row.plant_id
        
        # Initialize buffers if new plant
        if plant not in buffers:
            buffers[plant] = deque(maxlen=SEQUENCE_BUFFER)
            anomaly_history[plant] = deque(maxlen=ROLLING_WINDOW)
        
        # Preprocess and add to buffer
        row_scaled = preprocess_row(row.values)
        buffers[plant].append(row_scaled)
        
        # Build sequence (with padding if needed)
        seq = sequence_from_buffer(buffers[plant])
        
        # Compute reconstruction error
        raw_err, feature_err = compute_reconstruction_error(seq)
        raw_score = raw_err / THRESHOLD
        
        # Update anomaly history
        anomaly_history[plant].append(raw_score)
        
        # Normalized score for UI (capped at 1.0)
        normalized_score = min(raw_score, 1.0)
        
        # Rolling statistics
        rolling_avg, rolling_std = compute_rolling_stats(anomaly_history[plant])
        stability = calculate_stability_score(rolling_std)
        confidence = calculate_confidence(rolling_std, len(anomaly_history[plant]))
        
        # Determine severity
        severity = calculate_severity(raw_score, rolling_avg)
        
        # Generate AI analysis based on severity
        if severity == "normal":
            top_sensors = []
            root_cause = "No anomaly detected"
            recommendation = "System operating normally"
        else:
            top_sensors = get_top_contributing_sensors(feature_err, top_k=3)
            root_cause = determine_root_cause(top_sensors)
            recommendation = generate_recommendation(severity, top_sensors, root_cause)
        
        # Build response
        analytics = {
            "plant_id": plant,
            "timestamp": row.timestamp,
            "severity": severity,
            "anomaly_score": round(normalized_score, 4),
            "raw_anomaly_score": round(raw_score, 4),
            "confidence": round(confidence * 100, 2),
            "stability": round(stability, 2),
            "rolling_avg": round(rolling_avg, 4),
            "rolling_std": round(rolling_std, 4),
            "top_causes": [
                {"sensor": t["sensor"], "impact": round(t["error"], 4)}
                for t in top_sensors
            ],
            "root_cause": root_cause,
            "recommendation": recommendation,
            "buffer_len": len(buffers[plant]),
            "history_len": len(anomaly_history[plant]),
            "sequence_complete": len(buffers[plant]) >= SEQ_LEN
        }
        
        # Broadcast to WebSocket clients
        event = {"type": "prediction", **analytics}
        asyncio.create_task(manager.broadcast(event))
        
        return {"received": True, **analytics}
    
    except Exception as e:
        print(f"Ingest error: {e}")
        return {
            "received": False,
            "error": str(e),
            "plant_id": row.plant_id,
            "timestamp": row.timestamp
        }

# ---------------- WebSocket Endpoint ----------------

@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    """WebSocket endpoint for real-time updates"""
    await manager.connect(ws)
    try:
        # Send initial connection confirmation
        await ws.send_json({
            "type": "connection",
            "status": "connected",
            "message": "Real-time predictions active"
        })
        
        # Keep connection alive
        while True:
            await asyncio.sleep(1)
            
    except WebSocketDisconnect:
        manager.disconnect(ws)
    except Exception as e:
        print(f"WebSocket error: {e}")
        manager.disconnect(ws)

# ---------------- Health Check ----------------

@app.get("/health")
def health():
    """Health check endpoint"""
    return {
        "status": "ok",
        "model_loaded": True,
        "seq_len": SEQ_LEN,
        "sequence_buffer": SEQUENCE_BUFFER,
        "threshold": THRESHOLD,
        "columns": COLUMNS,
        "num_features": len(COLUMNS),
        "mode": "real-time"
    }

# ---------------- Status Endpoint ----------------

@app.get("/status/{plant_id}")
def status(plant_id: str = "plant_1"):
    """Get current status for a plant"""
    if plant_id not in buffers:
        return {
            "plant_id": plant_id,
            "status": "no_data",
            "buffer_len": 0,
            "history_len": 0
        }
    
    return {
        "plant_id": plant_id,
        "status": "active",
        "buffer_len": len(buffers[plant_id]),
        "history_len": len(anomaly_history[plant_id]),
        "sequence_complete": len(buffers[plant_id]) >= SEQ_LEN,
        "active_websockets": len(manager.active)
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)