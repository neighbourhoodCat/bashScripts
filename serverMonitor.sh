#!/bin/bash
#This is chatgpt code
INTERVAL=5

get_cpu_usage() {
    read cpu user nice system idle iowait irq softirq steal guest < /proc/stat
    total1=$((user + nice + system + idle + iowait + irq + softirq + steal))
    idle1=$((idle + iowait))

    sleep 1

    read cpu user nice system idle iowait irq softirq steal guest < /proc/stat
    total2=$((user + nice + system + idle + iowait + irq + softirq + steal))
    idle2=$((idle + iowait))

    total=$((total2 - total1))
    idle=$((idle2 - idle1))

    cpu_usage=$(( (100 * (total - idle)) / total ))
    echo "$cpu_usage"
}

get_memory_usage() {
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    mem_used=$((mem_total - mem_available))
    mem_percent=$((100 * mem_used / mem_total))
    echo "$mem_percent"
}

get_disk_usage() {
    df / | awk 'NR==2 {print $5}'
}

get_network_usage() {
    iface=$(ip route | awk '/default/ {print $5}')
    rx1=$(cat /sys/class/net/$iface/statistics/rx_bytes)
    tx1=$(cat /sys/class/net/$iface/statistics/tx_bytes)
    sleep 1
    rx2=$(cat /sys/class/net/$iface/statistics/rx_bytes)
    tx2=$(cat /sys/class/net/$iface/statistics/tx_bytes)

    rx_rate=$(( (rx2 - rx1) / 1024 ))
    tx_rate=$(( (tx2 - tx1) / 1024 ))

    echo "RX: ${rx_rate} KB/s | TX: ${tx_rate} KB/s"
}

while true; do
    clear
    echo "===== SERVER MONITOR ====="
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime -p)"
    echo "Load Average: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
    echo

    echo "CPU Usage: $(get_cpu_usage)%"
    echo "Memory Usage: $(get_memory_usage)%"
    echo "Disk Usage (/): $(get_disk_usage)"
    echo "Network: $(get_network_usage)"
    echo

    echo "Top 5 Processes by Memory:"
    ps -eo pid,comm,%mem,%cpu --sort=-%mem | head -n 6

    sleep $INTERVAL
done

echo "Do the flex before leave"
fastfetch