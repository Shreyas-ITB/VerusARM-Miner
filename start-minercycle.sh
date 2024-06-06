#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
fi

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

# Function to collect system information and save as JSON
collect_system_info() {
    while true; do
        # Get the system name
        local system_name=$(whoami)
        
        # Get the current temperature of the CPU
        local cpu_temp=$(vcgencmd measure_temp | egrep -o '[0-9]*\.[0-9]*')
        
        # Get the internet consumption (you can adjust the network interface as needed)
        local interface="wlan0" # Change this if using a different network interface
        local rx_bytes=$(cat /sys/class/net/$interface/statistics/rx_bytes)
        local tx_bytes=$(cat /sys/class/net/$interface/statistics/tx_bytes)
        local netcons=$(($rx_bytes + $tx_bytes))

        # Create a JSON object
        local json_data=$(jq -n --arg name "$system_name" --arg temp "$cpu_temp" --arg netcons "$netcons" \
            '{name: $name, temp: $temp, netcons: $netcons}')

        # Save JSON data to a file
        echo $json_data > system_info.json

        # Post the JSON data to the socket server
        if [ ! -z "$API" ]; then
            curl -X POST -H "Content-Type: application/json" -d "$json_data" "http://$API"
        else
            echo "API endpoint is not defined in the .env file."
        fi

        sleep 5m  # Run this every 5 minutes
    done
}

# Start collecting system info in the background
collect_system_info &

# Infinite loop to run the miner in cycles
while true; do
    start_miner
    echo "Miner running for 5 hours..."
    sleep 5h  # Run miner for 5 hours

    stop_miner
    echo "Miner resting for 10 minutes..."
    sleep 10m  # Rest for 10 minutes
done
