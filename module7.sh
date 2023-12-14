#!/bin/bash

check_essServices(){

    services=("ssh" "http" "https" "mysql")

    for service in "${services[@]}"; do
        sudo systemctl status "$service" >/dev/null 2>&1

        if [ $? -eq 0 ]; then 
            echo "$service is running."
        else
            echo "$service is not running."
        fi
    done
}


mintor_disk(){
threshold=80

df -h | tail -n +2 | while read -r filesystem size used available percentage mountpoint; do
    percentage=${percentage%\%}
    if [ "$percentage" -gt "$threshold" ]; then
        echo "Filesystem: $filesystem"
        echo "Usage: $percentage%"
        echo "-------------------"
    fi
done
}


check_ROnly(){
    readonly_file_systems=$(findmnt -o SOURCE,OPTIONS -n | awk '$2 ~ /ro/ {print $1}')

    if [ -n "$readonly_file_systems" ]; then
        echo "Read-only file systems:"
        echo "$readonly_file_systems"
        else
        echo "No read-only file systems found."
        fi
}

mintor_proeccess(){
    cpu_threshold=50
    memory_threshold=2000000 
    wanted_proc=$(ps -eo pid,%cpu,%mem,args |
                  awk -v cpu_threshold="$cpu_threshold" -v memory_threshold="$memory_threshold" '$2 > cpu_threshold || $3 > memory_threshold {print $1}')

    if [ -n "$wanted_proc" ]; then 
         echo "Processes exceeding thresholds:"
         echo "$wanted_proc"
        else
        echo "No processes exceed the thresholds."
    fi
}

analyze_logs(){
    log_files="/var/log/syslog /var/log/messages"
    output_file="log_analysis.txt"

    grep -i 'error\|warning' $log_files > $output_file

    if [ -s $output_file ]; then
        echo "Analysis Results: Errors and Warnings found."
        cat $output_file
    else
        echo "No Errors or Warnings found in the logs."
    fi
    }


security_check1(){
    file_logs="/var/log/auth.log"

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
   

main(){
    echo "Performing System Health Check and Performance Monitoring..."
    echo "___________check_essServices____________________"
    check_essServices
    echo "_______________mintor_disk____________________"
    mintor_disk
    echo "_______________check_ROnly____________________"
    check_ROnly
    echo "_______________mintor_proeccess____________________"
    mintor_proeccess
    echo "________________analyze_logs_______________________"
    analyze_logs
}


main