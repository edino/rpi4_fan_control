
import os
import subprocess
from datetime import datetime
import time

# Function to log commands
def log_command(command, description, log_file):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S_%Z')
    with open(log_file, 'a') as f:
        f.write(f"[{timestamp}] {description}\n")
        f.write(f"[{timestamp}] Running: {command}\n")
        result = subprocess.run(command, shell=True, stdout=f, stderr=subprocess.STDOUT)
        f.write(f"[{timestamp}] Finished: {command}\n\n")
    return result
    
# Main function
def main():
    # Get the output of the nvram command
    nvram_output = subprocess.run(["nvram", "get", "#li.serial"], capture_output=True, text=True).stdout.strip()

    # Log file path
    log_file = f"/var/tam_healthcheck_{nvram_output}-{datetime.now().strftime('%Y-%m-%d_at_%H:%M:%S_%Z')}.log"
    print(f"Executing commands and saving output to {log_file} ...")

    log_command("date", "Display current date and time", log_file)
    log_command("uptime", "Show system uptime and load", log_file)
    log_command("nvram get '#'li.serial", "Get the serial number of the device", log_file)
    log_command("df -kh", "Show disk space usage", log_file)
    log_command("grep 'cpu cores' /proc/cpuinfo | wc -l", "Count the number of CPU cores", log_file)
    log_command("cat /proc/scsi/scsi", "Display SCSI devices", log_file)
    log_command("hdparm -i /dev/sda", "Show information about the hard drive /dev/sda", log_file)
    log_command("fdisk -l", "List disk partitions", log_file)
    log_command("dmidecode -s system-version", "Show the system version", log_file)
    log_command("showfw", "Show firmware information", log_file)
    log_command("csc custom status", "Show the status of custom CSC (Customizable Service Code) settings", log_file)
    log_command("service -S | sort -f", "List all services sorted alphabetically", log_file)
    log_command("service -S | sort -f | grep -v RUN", "List services that are not running", log_file)
    log_command("central-register --status", "Show status of central registration", log_file)
    log_command("central-connect --check_status", "Check central connect status", log_file)
    log_command("nsgenc status; echo $?", "Show NSGenc status", log_file)
    log_command("psql -U nobody -d signature -p 5434 -tAc 'select * from public.tblup2dateinfo;'", "Show up-to-date information from a PostgreSQL database", log_file)
    log_command("tcpdump -D", "List available network interfaces for packet capture", log_file)
    log_command("listif -s", "List network interfaces with statistics", log_file)
    log_command("netstat -i", "List network interfaces and their statistics", log_file)
    log_command("psql -U nobody -d corporate -c 'select * from tblipaddress;'", "Show IP addresses from a PostgreSQL database", log_file)
    log_command("route -n", "Show the routing table", log_file)
    log_command("ip route get 8.8.8.8", "Get route information for the IP address 8.8.8.8", log_file)
    log_command("nslookup eu1.apu.sophos.com", "Perform a DNS lookup for eu1.apu.sophos.com", log_file)
    log_command("ls -l /var/cores/", "List core files in /var/cores/", log_file)
    log_command("cat /proc/sys/net/ipv4/tcp_fastopen", "Show TCP Fast Open setting", log_file)
    log_command("/scripts/firewall/manage_fastpath.sh show", "Show Fast Path setting for the firewall", log_file)
    log_command("arp -a | grep -v inc | wc -l", "Count ARP entries (excluding incomplete entries)", log_file)
    log_command("conntrack -L | grep ESTABLISHED | wc -l", "Count established connections using conntrack", log_file)
    log_command("ipset -L lusers | wc -l", "Count IP addresses in the lusers IP set", log_file)
    log_command("curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -", "Run a speed test using speedtest-cli", log_file)
    log_command('cish -c "system diagnostics show version-info"', "System Check Information Details", log_file)
    log_command('cish -c "system ha show details"', "High Availability Check Information Details", log_file)
    log_command('smartctl -a /dev/sda |grep "Device Model";smartctl -a /dev/sda | grep "Firmware Version"', "Disk Model and Firmware Details", log_file)
    log_command('smartctl -a /dev/sdb |grep "Device Model";smartctl -a /dev/sdb | grep "Firmware Version"', "Disk Model and Firmware Details", log_file)
    log_command('grep -i "exception Emask .* SAct .* SErr .* action .*\|Unrecovered read error\|I/O error" /var/tslog/syslog.log*', "Check for Disk Errors", log_file)
    log_command('grep -i "DRDY ERR" /var/tslog/syslog.log*', "Check for Disk Errors", log_file)
    log_command('grep -i "drdy\|i/o\|segfault" /var/tslog/syslog.log*', "Check for Disk Errors", log_file)
    log_command('grep -i "media error" /var/tslog/syslog.log*', "Check for Disk Errors - This Particular error supports a straight RMA if the timestamp is recent and appliance has valid warranty", log_file)
    log_command("opcode ctr -ds nosync -t json -b '{"problemdesc":"debugging purpose","logs":"1","systemsnap":"1"}'", "Generate a Full CTR (Consolidated troubleshooting report) containing System snapshot and Log Files, CTR file is stored at /sdisk/ctrfinal/", log_file)
    log_command('tar -czvf /var/log_Master-$(nvram get "#li.serial")-$(date +"%Y-%m-%d_at_%T_%Z").tar.gz /var/tslog/*.log* /var/tslog/*.gz* | ls -lah /var/log_Master*', "Compress Appliance Logs to be collected", log_file)
    log_command('tar -czvf /var/kdump_Master-$(nvram get "#li.serial")-$(date +"%Y-%m-%d_at_%T_%Z").tar.gz /var/crashkernel/* | ls -lah /var/kdump_Master*', "Compress Crash Kernel Dumps to be collected", log_file)
    log_command('tar -czvf /var/core_dump_Master-$(nvram get "#li.serial")-$(date +"%Y-%m-%d_at_%T_%Z").tar.gz /var/cores/* | ls -lah /var/core_dump_Master*', "Compress Core Dumps to be collected", log_file)

# Check if running as root
if os.geteuid() != 0:
    print("This script must be run as root")
    exit(1)

try:
    # Call main function
    main()
except KeyboardInterrupt:
    print("Script execution was manually interrupted by the user.")
    exit(1)
