import os
import subprocess
from datetime import datetime

# Log file path
log_file = f"/var/tam_healthcheck_{os.getenv('#li.serial')}-{datetime.now().strftime('%Y-%m-%d_at_%H:%M:%S_%Z')}.log"

# Function to log commands
def log_command(command, description):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    with open(log_file, 'a') as f:
        f.write(f"[{timestamp}] {description}\n")
        f.write(f"[{timestamp}] Running: {command}\n")
        result = subprocess.run(command, shell=True, stdout=f, stderr=subprocess.STDOUT)
        f.write(f"[{timestamp}] Finished: {command}\n\n")
    return result

# Main function
def main():
    print(f"Executing commands and saving output to {log_file} ...")

    log_command("date", "Display current date and time")
    log_command("uptime", "Show system uptime and load")
    log_command("nvram get '#'li.serial", "Get the serial number of the device")
    log_command("nvram get '#'li.master", "Get the master setting value")
    log_command("df -kh", "Show disk space usage")
    log_command("grep 'cpu cores' /proc/cpuinfo | wc -l", "Count the number of CPU cores")
    log_command("cat /proc/scsi/scsi", "Display SCSI devices")
    log_command("hdparm -i /dev/sda", "Show information about the hard drive /dev/sda")
    log_command("fdisk -l", "List disk partitions")
    log_command("dmidecode -s system-version", "Show the system version")
    log_command("showfw", "Show firmware information")
    log_command("csc custom status", "Show the status of custom CSC (Customizable Service Code) settings")
    log_command("service -S | sort -f", "List all services sorted alphabetically")
    log_command("service -S | sort -f | grep -v RUN", "List services that are not running")
    log_command("central-register --status", "Show status of central registration")
    log_command("central-connect --check_status", "Check central connect status")
    log_command("nsgenc status; echo $?", "Show NSGenc status")
    log_command("psql -U nobody -d signature -p 5434 -tAc 'select * from public.tblup2dateinfo;'", "Show up-to-date information from a PostgreSQL database")
    log_command("tcpdump -D", "List available network interfaces for packet capture")
    log_command("listif -s", "List network interfaces with statistics")
    log_command("netstat -i", "List network interfaces and their statistics")
    log_command("psql -U nobody -d corporate -c 'select * from tblipaddress;'", "Show IP addresses from a PostgreSQL database")
    log_command("route -n", "Show the routing table")
    log_command("ip route get 8.8.8.8", "Get route information for the IP address 8.8.8.8")
    log_command("nslookup eu1.apu.sophos.com", "Perform a DNS lookup for eu1.apu.sophos.com")
    log_command("ls -l /var/cores/", "List core files in /var/cores/")
    log_command("cat /proc/sys/net/ipv4/tcp_fastopen", "Show TCP Fast Open setting")
    log_command("/scripts/firewall/manage_fastpath.sh show", "Show Fast Path setting for the firewall")
    log_command("arp -a | grep -v inc | wc -l", "Count ARP entries (excluding incomplete entries)")
    log_command("conntrack -L | grep ESTABLISHED | wc -l", "Count established connections using conntrack")
    log_command("ipset -L lusers | wc -l", "Count IP addresses in the lusers IP set")
    log_command("curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -", "Run a speed test using speedtest-cli")
    log_command("cish -c "system diagnostics show version-info"", "System Check Information Details")
    log_command("cish -c "system ha show details"", "High Availability Check Information Details")
    log_command("smartctl -a /dev/sda |grep "Device Model";smartctl -a /dev/sda | grep "Firmware Version"", "Disk Model and Firmware Details")
    log_command("smartctl -a /dev/sdb |grep "Device Model";smartctl -a /dev/sdb | grep "Firmware Version"", "Disk Model and Firmware Details")
    log_command("grep -i "exception Emask .* SAct .* SErr .* action .*\|Unrecovered read error\|I/O error" /var/tslog/syslog.log*", "Check for Disk Errors")
    log_command("grep -i "DRDY ERR" /var/tslog/syslog.log*", "Check for Disk Errors")
    log_command("grep -i "drdy\|i/o\|segfault" /var/tslog/syslog.log*", "Check for Disk Errors")
    log_command("grep -i "media error" /var/tslog/syslog.log*", "Check for Disk Errors - This Particular error supports a straight RMA if the timestamp is recent and appliance has valid warranty")
    log_command("tar -czvf /var/log_Master-$(nvram get "#li.serial")-$(date +"%Y-%m-%d_at_%T_%Z").tar.gz /var/tslog/*.log* /var/tslog/*.gz*", "Compress Appliance Logs to be collected")
    log_command("tar -czvf /var/kdump_Master-$(nvram get "#li.serial")-$(date +"%Y-%m-%d_at_%T_%Z").tar.gz /var/crashkernel/*", "Compress Crash Kernel Dumps to be collected")
    log_command("tar -czvf /var/cores_Master-$(nvram get "#li.serial")-$(date +"%Y-%m-%d_at_%T_%Z").tar.gz /var/cores/*", "Compress Core Dumps to be collected")

# Check if running as root
if os.geteuid() != 0:
    print("This script must be run as root")
    exit(1)

# Call main function
main()

# Add cleanup code here...
