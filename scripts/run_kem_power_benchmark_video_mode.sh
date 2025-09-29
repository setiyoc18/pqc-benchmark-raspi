#!/bin/bash

# Get input from user
read -p "Enter the name of the algorithm (e.g.: ML-KEM-512): " algorithm
read -p "Enter benchmark duration (seconds): " duration

# Basic directory and file setup
destination_dir="/home/pi/benchmark_logs"
mkdir -p $destination_dir

# Loop 3 times benchmark
for i in {1..3}; do
    timestamp=$(date +"%Y%m%d_%H%M%S")
    benchmark_output="/dev/shm/output_${algorithm// /_}_run${i}_$timestamp.txt"

    echo ""
    echo " [Run $i] Record the Raspberry Pi idle process now for 10 seconds..."
    for t in {10..1}; do
        echo -ne "   Records idle current... (${t}s)\r"
        sleep 1
    done

    echo ""
    echo " [Run $i] Get ready to run the $algorithm benchmark in 10 seconds..."
    for t in {10..1}; do
        echo -ne "   Start benchmarking in ${t}s...\r"
        sleep 1
    done

    echo -e "\n Running benchmarks..."
    start=$(date +%s)
    ./tests/speed_kem "$algorithm" --duration "$duration" --info > $benchmark_output
    end=$(date +%s)
    runtime=$((end - start))

    echo ""
    echo " Benchmark complete. Continue recording until the system is idle again (if necessary)." 
    cp $benchmark_output $destination_dir/

    echo ""
    echo " Run $i completed. Results moved to  $destination_dir/"
    echo "---------------------------------------------"
    sleep 2
done

echo " All benchmark results for the $algorithm algorithm have been saved.."
