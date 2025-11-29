"""
Generate sample NYC taxi data for testing
Run this locally and upload to S3 manually or via CI/CD
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os

def generate_nyc_taxi_data(num_records=10000):
    """Generate sample NYC taxi trip data"""
    
    np.random.seed(42)
    
    # Generate timestamps
    start_date = datetime(2024, 1, 1)
    pickup_times = [start_date + timedelta(
        hours=np.random.randint(0, 24*30),
        minutes=np.random.randint(0, 60)
    ) for _ in range(num_records)]
    
    # Generate trip durations (5 to 60 minutes)
    trip_durations = np.random.randint(5, 60, num_records)
    dropoff_times = [pickup + timedelta(minutes=int(duration)) 
                     for pickup, duration in zip(pickup_times, trip_durations)]
    
    # Generate other fields
    data = {
        'vendorid': np.random.choice([1, 2], num_records),
        'tpep_pickup_datetime': pickup_times,
        'tpep_dropoff_datetime': dropoff_times,
        'passenger_count': np.random.choice([1, 2, 3, 4, 5, 6], num_records, 
                                           p=[0.5, 0.3, 0.1, 0.05, 0.03, 0.02]),
        'trip_distance': np.round(np.random.exponential(3, num_records), 2),
        'ratecodeid': np.random.choice([1, 2, 3, 4, 5], num_records, 
                                      p=[0.85, 0.05, 0.05, 0.03, 0.02]),
        'store_and_fwd_flag': np.random.choice(['N', 'Y'], num_records, 
                                               p=[0.95, 0.05]),
        'pulocationid': np.random.randint(1, 265, num_records),
        'dolocationid': np.random.randint(1, 265, num_records),
        'payment_type': np.random.choice([1, 2, 3, 4], num_records, 
                                        p=[0.7, 0.25, 0.03, 0.02]),
        'fare_amount': np.round(np.random.uniform(5, 50, num_records), 2),
        'extra': np.round(np.random.choice([0, 0.5, 1], num_records, 
                                          p=[0.7, 0.2, 0.1]), 2),
        'mta_tax': np.full(num_records, 0.5),
        'tip_amount': np.round(np.random.uniform(0, 10, num_records), 2),
        'tolls_amount': np.round(np.random.choice([0, 5.76, 8.50], num_records, 
                                                  p=[0.8, 0.1, 0.1]), 2),
        'improvement_surcharge': np.full(num_records, 0.3),
        'total_amount': 0,  # Will calculate
        'congestion_surcharge': np.round(np.random.choice([0, 2.5], num_records, 
                                                          p=[0.3, 0.7]), 2),
        'airport_fee': np.round(np.random.choice([0, 1.25], num_records, 
                                                 p=[0.9, 0.1]), 2)
    }
    
    df = pd.DataFrame(data)
    
    # Calculate total amount
    df['total_amount'] = (
        df['fare_amount'] + 
        df['extra'] + 
        df['mta_tax'] + 
        df['tip_amount'] + 
        df['tolls_amount'] + 
        df['improvement_surcharge'] + 
        df['congestion_surcharge'] + 
        df['airport_fee']
    ).round(2)
    
    return df

if __name__ == "__main__":
    print("Generating sample NYC taxi data...")
    df = generate_nyc_taxi_data(10000)
    
    # Create output directory
    output_dir = "sample_data"
    os.makedirs(output_dir, exist_ok=True)
    
    # Save as CSV
    csv_path = f"{output_dir}/nyc_taxi_sample.csv"
    df.to_csv(csv_path, index=False)
    print(f"Saved CSV to: {csv_path}")
    
    # Save as Parquet
    parquet_path = f"{output_dir}/nyc_taxi_sample.parquet"
    df.to_parquet(parquet_path, index=False)
    print(f"Saved Parquet to: {parquet_path}")
    
    # Display sample
    print("\nSample data:")
    print(df.head())
    print(f"\nTotal records: {len(df)}")
    print(f"Date range: {df['tpep_pickup_datetime'].min()} to {df['tpep_pickup_datetime'].max()}")