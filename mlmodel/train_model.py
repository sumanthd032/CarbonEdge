# train_model.py
# Usage: python train_model.py --csv kiln_dataset.csv --seq_len 60 --epochs 20

import argparse
import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.preprocessing import StandardScaler
import os
import json
import joblib

def load_csv(path):
    """Load CSV and handle missing values robustly"""
    df = pd.read_csv(path)
    print(f"✓ Loaded {len(df)} rows from {path}")
    
    # Select only numeric columns
    df = df.select_dtypes(include=[np.number])
    
    # Handle missing values: forward fill, then backward fill, then zeros
    df = df.fillna(method='ffill').fillna(method='bfill').fillna(0)
    
    print(f"✓ Using {len(df.columns)} numeric columns")
    return df

def create_sequences(values, seq_len):
    """Create sliding window sequences for LSTM autoencoder"""
    sequences = []
    for i in range(len(values) - seq_len + 1):
        sequences.append(values[i:i+seq_len])
    return np.array(sequences)

def build_autoencoder(seq_len, n_features, latent_dim=32):
    """Build robust LSTM autoencoder with dropout for stability"""
    inp = tf.keras.layers.Input(shape=(seq_len, n_features))
    
    # Encoder
    x = tf.keras.layers.LSTM(128, return_sequences=True, dropout=0.2)(inp)
    x = tf.keras.layers.LSTM(64, return_sequences=False, dropout=0.2)(x)
    x = tf.keras.layers.Dense(latent_dim, activation='relu')(x)
    
    # Decoder
    x = tf.keras.layers.RepeatVector(seq_len)(x)
    x = tf.keras.layers.LSTM(64, return_sequences=True, dropout=0.2)(x)
    x = tf.keras.layers.LSTM(128, return_sequences=True, dropout=0.2)(x)
    out = tf.keras.layers.TimeDistributed(tf.keras.layers.Dense(n_features))(x)
    
    model = tf.keras.models.Model(inp, out)
    model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=0.001), loss='mse')
    return model

def compute_threshold(model, sequences, percentile=99):
    """Compute anomaly threshold using percentile of reconstruction errors"""
    preds = model.predict(sequences, verbose=0)
    # MSE per sequence: mean over time and features
    mse = np.mean(np.square(preds - sequences), axis=(1, 2))
    threshold = float(np.percentile(mse, percentile))
    return threshold, mse

def main(args):
    print("\n" + "="*70)
    print("🔧 CarbonEdge AI - Model Training Pipeline")
    print("="*70)
    
    # Load data
    df = load_csv(args.csv)
    column_names = list(df.columns)
    values = df.values.astype('float32')
    
    # Scale data
    print("\n✓ Fitting StandardScaler...")
    scaler = StandardScaler()
    values_scaled = scaler.fit_transform(values)
    
    # Create sequences
    seq_len = args.seq_len
    print(f"\n✓ Creating sequences (seq_len={seq_len})...")
    seqs = create_sequences(values_scaled, seq_len)
    print(f"  Generated {len(seqs)} sequences of shape {seqs.shape}")
    
    # Train/val split
    N = len(seqs)
    split = int(N * 0.8)
    x_train = seqs[:split]
    x_val = seqs[split:]
    print(f"\n✓ Train: {len(x_train)} sequences | Val: {len(x_val)} sequences")
    
    # Build model
    n_features = values.shape[1]
    print(f"\n✓ Building LSTM Autoencoder (features={n_features}, latent_dim={args.latent})...")
    model = build_autoencoder(seq_len, n_features, latent_dim=args.latent)
    model.summary()
    
    # Train
    print("\n✓ Training model...")
    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor='val_loss', 
            patience=5, 
            restore_best_weights=True,
            verbose=1
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=3,
            verbose=1
        )
    ]
    
    history = model.fit(
        x_train, x_train,
        epochs=args.epochs,
        batch_size=args.batch,
        validation_data=(x_val, x_val),
        callbacks=callbacks,
        verbose=1
    )
    
    # Compute threshold
    print("\n✓ Computing anomaly threshold...")
    threshold, val_errors = compute_threshold(model, x_val, percentile=args.percentile)
    print(f"  {args.percentile}th percentile threshold: {threshold:.6f}")
    print(f"  Mean val error: {np.mean(val_errors):.6f}")
    print(f"  Std val error: {np.std(val_errors):.6f}")
    
    # Save artifacts
    out_dir = args.out_dir
    os.makedirs(out_dir, exist_ok=True)
    
    print(f"\n✓ Saving model to {out_dir}...")
    model.save(os.path.join(out_dir, 'ae_model'))
    joblib.dump(scaler, os.path.join(out_dir, 'scaler.pkl'))
    
    meta = {
        'columns': column_names,
        'seq_len': seq_len,
        'threshold': threshold,
        'n_features': n_features,
        'percentile': args.percentile,
        'val_mean_error': float(np.mean(val_errors)),
        'val_std_error': float(np.std(val_errors))
    }
    
    with open(os.path.join(out_dir, 'meta.json'), 'w') as f:
        json.dump(meta, f, indent=2)
    
    print(f"\n{'='*70}")
    print("✅ Training complete! Model artifacts saved.")
    print(f"{'='*70}\n")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Train CarbonEdge LSTM Autoencoder')
    parser.add_argument('--csv', required=True, help='Path to training CSV file')
    parser.add_argument('--seq_len', type=int, default=60, help='Sequence length for LSTM')
    parser.add_argument('--latent', type=int, default=32, help='Latent dimension size')
    parser.add_argument('--epochs', type=int, default=20, help='Training epochs')
    parser.add_argument('--batch', type=int, default=64, help='Batch size')
    parser.add_argument('--percentile', type=int, default=99, help='Threshold percentile (95-99)')
    parser.add_argument('--out_dir', default='carbonedge_model', help='Output directory')
    args = parser.parse_args()
    main(args)