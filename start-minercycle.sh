#!/bin/bash

# Function to start the miner
start_miner() {
    echo "Cleaning up existing screen sessions..."
    # Kill all existing CCminer screen sessions
    screen -ls | grep 'CCminer' | grep Detached | awk '{print $1}' | xargs -I {} screen -X -S {} quit
    screen -ls | grep 'CCminer' | grep Dead | awk '{print $1}' | xargs -I {} screen -wipe

    echo "Starting the miner..."
    ./ccminer/start.sh
}

# Function to stop the miner
stop_miner() {
    echo "Stopping the miner..."
    screen -X -S CCminer quit
}

# Function to handle script exit
cleanup_and_exit() {
    echo "Quitting the script and the miner.. sad to see you go!"
    stop_miner
    screen -ls | grep 'CCminer' | grep Detached | awk '{print $1}' | xargs -I {} screen -X -S {} quit
    screen -ls | grep 'CCminer' | grep Dead | awk '{print $1}' | xargs -I {} screen -wipe
    exit 0
}

# Trap SIGINT (CTRL+C) to run the cleanup_and_exit function
trap cleanup_and_exit SIGINT

# Infinite loop to run the miner in cycles
while true; do
    start_miner
    echo "Miner running for 3 hours..."
    sleep 5h  # Run miner for 3 hours

    stop_miner
    echo "Miner resting for 10 minutes..."
    sleep 10m  # Rest for 10 minutes
done
