#!/bin/bash

log_file="system_health_check.log"

log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" >> "$log_file"
}

check_essServices(){
    log "Checking essential services..."

    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    services=("ssh" "http" "https" "mysql")

    # Check if systemctl is available
    command -v systemctl >/dev/null 2>&1 || { echo >&2 "systemctl not found. Exiting."; exit 1; }

    # Check if services exist
    for service in "${services[@]}"; do
        systemctl is-active --quiet "$service" || { echo >&2 "Service not found: $service";}
    done

    for service in "${services[@]}"; do
        sudo systemctl status "$service" >/dev/null 2>&1

        if [ $? -eq 0 ]; then 
            echo " at $timestamp $service is running."
        else
            echo "at $timestamp $service is not running."
        fi
    done
}


mintor_disk(){
    log "Monitoring disk usage..."
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    threshold=80

    df -h | tail -n +2 | while read -r filesystem size used available percentage mountpoint; do
        percentage=${percentage%\%}
        if [ "$percentage" -gt "$threshold" ]; then
        echo "at $timestamp"
            echo "Filesystem: $filesystem"
            echo "Usage: $percentage%"
            echo "-------------------"
        fi
    done
}


check_ROnly() {
    log "Checking read-only file systems..."
    # Get timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    # Find read-only file systems
    readonly_file_systems=$(findmnt -o SOURCE,OPTIONS -n | awk '$2 ~ /ro/ {print $1}')

    # Print results with timestamp
    if [ -n "$readonly_file_systems" ]; then
        echo "$timestamp - Read-only file systems:"
        echo "$readonly_file_systems"
    else
        echo "$timestamp - No read-only file systems found."
    fi
}

mintor_proeccess() {
    log "Monitoring processes..."
    # Get timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    cpu_threshold=50
    memory_threshold=2000000 

    # Find processes exceeding thresholds
    wanted_proc=$(ps -eo pid,%cpu,%mem,args |
                  awk -v cpu_threshold="$cpu_threshold" -v memory_threshold="$memory_threshold" '$2 > cpu_threshold || $3 > memory_threshold {print $1}')

    # Print results with timestamp
    if [ -n "$wanted_proc" ]; then 
         echo "$timestamp - Processes exceeding thresholds:"
         echo "$wanted_proc"
    else
        echo "$timestamp - No processes exceed the thresholds."
    fi
}


analyze_logs() {
    log "Analyzing logs..."
    # Get timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    # Log files to check
    log_files=("/var/log/syslog" "/var/log/messages")

    for log_file in "${log_files[@]}"; do
        # Check if log file exists
        if [ -e "$log_file" ]; then
            # Search for 'error' or 'warning' in log files
            grep -i 'error\|warning' "$log_file" > "$log_file"_analysis.txt

            # Print results with timestamp
            if [ -s "$log_file"_analysis.txt ]; then
                echo "$timestamp - Analysis Results for $log_file: Errors and Warnings found."
                cat "$log_file"_analysis.txt
            else
                echo "$timestamp - No Errors or Warnings found in $log_file."
            fi
        else
            echo "$timestamp - Log file not found: $log_file"
        fi
    done
}




security_check1(){
    log "Performing security check 1..."
    file_logs="/var/log/auth.log"

    # Check if log file exists
    [ -e "$file_logs" ] || { echo >&2 "Authentication log file not found: $file_logs"; exit 1; }

    # Check if log analysis tools are available
    command -v grep awk >/dev/null 2>&1 || { echo >&2 "Required tools (grep, awk) not found. Exiting."; exit 1; }


    if [ ! -f "$file_logs" ]; then
        echo "Authentication log file not found: $file_logs"
        exit 1
    fi

    failed_attempts=$(cat $file_logs | grep "Failed")

    echo "Unauthorized Access Attempts:"
    echo "-------------------------------"

    if [ -n "$failed_attempts" ]; then
        echo "$failed_attempts" | sort | uniq -c | while read count username ip; do
            first_attempt=$(grep "$ip" "$file_logs" | grep "$username" | awk '{print $1, $3}' | head -n 1)
            last_attempt=$(grep "$ip" "$file_logs" | grep "$username" | awk '{print $1, $3}' | tail -n 1)

            echo "Username: $username"
            echo "Count of Attempts: $count"
            echo "First Attempt Date: $first_attempt"
            echo "Last Attempt Date: $last_attempt"
            echo "-------------------------------"
        done
            else
            echo "No unauthorized access attempts found."
    fi

}


security_check2(){
log "Performing security check 2..."
# Check if nmap is available
command -v nmap >/dev/null 2>&1 || { echo >&2 "nmap not found. Exiting."; exit 1; }

 nmap_output=$(nmap localhost)

# Check for unexpected open ports
unexpected_ports=$(echo "$nmap_output" | grep -E "^\d+/tcp\s+open" | awk '{print $1}')

if [ -z "$unexpected_ports" ]; then
    echo "No unexpected open ports found."
else
    echo "Unexpected open ports found:"
    echo "$unexpected_ports"
fi
}
   

main(){
    log "Performing System Health Check and Performance Monitoring..."
    check_essServices
    mintor_disk
    check_ROnly
    mintor_proeccess
    analyze_logs
    security_check1
    security_check2
}


main >> "$log_file"