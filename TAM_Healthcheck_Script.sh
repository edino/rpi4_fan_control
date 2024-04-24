## To execute the script:
## curl -sL https://raw.githubusercontent.com/yourusername/yourrepository/master/yourscript.sh | bash

#!/bin/sh

# Log file path
log_file="/var/tam_healthcheck_$(nvram get '#li.serial')-$(date +"%Y-%m-%d_at_%T_%Z").log"

# Function to log commands
log_command() {
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    command="$1"
    description="$2"
    echo "[$timestamp] $description" >> $log_file
    echo "[$timestamp] Running: $command" >> $log_file
    eval "$command" >> $log_file 2>&1
    echo "[$timestamp] Finished: $command" >> $log_file
    echo "" >> $log_file
}

# Main function
main() {
    echo "Executing commands and saving output to $log_file ..."

    log_command "date" "Display current date and time"
    log_command "uptime" "Show system uptime and load"
    log_command "nvram get '#'li.serial" "Get the serial number of the device"
    log_command "nvram get '#'li.master" "Get the master setting value"
    log_command "df -kh" "Show disk space usage"
    log_command "grep 'cpu cores' /proc/cpuinfo | wc -l" "Count the number of CPU cores"
    log_command "cat /proc/scsi/scsi" "Display SCSI devices"
    log_command "hdparm -i /dev/sda" "Show information about the hard drive /dev/sda"
    log_command "fdisk -l" "List disk partitions"
    log_command "dmidecode -s system-version" "Show the system version"
    log_command "showfw" "Show firmware information"
    log_command "csc custom status" "Show the status of custom CSC (Customizable Service Code) settings"
    log_command "service -S | sort -f" "List all services sorted alphabetically"
    log_command "service -S | sort -f | grep -v RUN" "List services that are not running"
    log_command "central-register --status" "Show status of central registration"
    log_command "central-connect --check_status" "Check central connect status"
    log_command "nsgenc status; echo $?" "Show NSGenc status"
    log_command "psql -U nobody -d signature -p 5434 -tAc 'select * from public.tblup2dateinfo;'" "Show up-to-date information from a PostgreSQL database"
    log_command "tcpdump -D" "List available network interfaces for packet capture"
    log_command "listif -s" "List network interfaces with statistics"
    log_command "netstat -i" "List network interfaces and their statistics"
    log_command "psql -U nobody -d corporate -c 'select * from tblipaddress;'" "Show IP addresses from a PostgreSQL database"
    log_command "route -n" "Show the routing table"
    log_command "ip route get 8.8.8.8" "Get route information for the IP address 8.8.8.8"
    log_command "nslookup eu1.apu.sophos.com" "Perform a DNS lookup for eu1.apu.sophos.com"
    log_command "ls -l /var/cores/" "List core files in /var/cores/"
    log_command "cat /proc/sys/net/ipv4/tcp_fastopen" "Show TCP Fast Open setting"
    log_command "/scripts/firewall/manage_fastpath.sh show" "Show Fast Path setting for the firewall"
    log_command "arp -a | grep -v inc | wc -l" "Count ARP entries (excluding incomplete entries)"
    log_command "conntrack -L | grep ESTABLISHED | wc -l" "Count established connections using conntrack"
    log_command "ipset -L lusers | wc -l" "Count IP addresses in the lusers IP set"
    log_command "curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -" "Run a speed test using speedtest-cli"
}

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Call main function
main

# Add cleanup code here...
