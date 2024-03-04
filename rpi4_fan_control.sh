#!/bin/bash

##############################################################################
# Copyright (c) [2024] [Edino De Souza]
# Original author: Edino De Souza
# Repository: https://github.com/edino/rpi4_fan_control
# License: GPL-3.0 license - https://github.com/edino/rpi4_fan_control/tree/main?tab=GPL-3.0-1-ov-file
##############################################################################


# The FAN tested with this script is the one listed below:

# [GeeekPi Aluminum Heatsink with PWM Controllable Fan for Raspberry Pi 4, Pi 4 Armor Lite Heatsink with PWM Speed Control Fan for Raspberry Pi 4 Model B](https://www.amazon.ca/GeeekPi-Raspberry-Aluminum-Heatsink-Controllable/dp/B091L1XKL6)

# Script Summary: Control fan speed based on CPU temperature using GPIO pin. Temp range 30-70°C, adjusting PWM values.

# Purpose: The purpose of the script is to control the fan speed of a Raspberry Pi 4 based on the CPU temperature. It defines temperature thresholds and adjusts the PWM values to set the fan speed accordingly. The script continuously monitors the CPU temperature and adjusts the fan speed to maintain it within the specified range, aiming to provide effective cooling while minimizing noise.

# Pre-requisites to run this script as a system service:
# 0. apt install pigpiod bc lm-sensors cpufrequtils -y
# 0.5. Add GPI18 entry at config.txt file: grep -q "^dtoverlay=gpio-fan,gpiopin=18" /boot/firmware/config.txt || echo "dtoverlay=gpio-fan,gpiopin=18" | sudo tee -a /boot/firmware/config.txt
# 1. Download the script using: curl -vlO https://raw.githubusercontent.com/edino/rpi4_fan_control/main/rpi4_fan_control.sh
# 1.1 Ensure the script is executable: chmod +x /usr/local/bin/rpi4_fan_control.sh
# 2. Create a systemd service unit file:
#    - Create a new unit file: sudo nano /etc/systemd/system/rpi4_fan_control.service
#    - Add the following content to the file (replace /usr/local/bin/rpi4_fan_control.sh with the actual path to your script):
## Service starts here:
#      [Unit]
#      Description=Fan Control Service
#      After=network.target
#      
#      [Service]
#      ExecStart=/usr/local/bin/rpi4_fan_control.sh
#      ReadWritePaths=/sys/class/hwmon/hwmon1/
#      Restart=always
#      
#      [Install]
#      WantedBy=multi-user.target
## Service ends here:
# 3. Reload systemd: sudo systemctl daemon-reload
# 4. Enable the service to start on boot: sudo systemctl enable --now frpi4_fan_control.service
# 5. Check the status of the service: sudo systemctl status rpi4_fan_control.service

# BuildDate: 01:08 PM EST 2024-03-04

# GPIO pin number for fan control
FAN_PIN=18

# Temperature thresholds
MIN_TEMP=35
MAX_TEMP=60
TEMP_STEP=$((($MAX_TEMP - $MIN_TEMP) * 10 / 255))
if ((TEMP_STEP == 0)); then
    TEMP_STEP=1
fi
echo "MIN_TEMP: $MIN_TEMP, MAX_TEMP: $MAX_TEMP, TEMP_STEP: $TEMP_STEP"

# Define PWM_VALUES array
PWM_VALUES=()
for i in $(seq 0 255); do
    PWM_VALUES[$i]=$i
done

# Function to map temperature to fan speed PWM value
map_temp_to_pwm() {
    local temp=$1
    if ((temp < MIN_TEMP)); then
        echo 0
    else
        local index=$(awk -v temp=$temp -v min=$MIN_TEMP -v step=$TEMP_STEP 'BEGIN { printf "%.0f", (temp - min) * 10 / step }')
        if ((index < 0)); then
            index=0
        elif ((index >= 255)); then
            index=255
        fi
        echo ${PWM_VALUES[$index]}
    fi
}

# Log file
LOG_FILE="/var/log/fan_control.log"

# Function to set fan speed
set_fan_speed() {
    speed=$1
    speed_hex=$(echo "obase=16; $speed" | bc)  # Convert speed to hexadecimal
    pigs p $FAN_PIN "0x$speed_hex"
    echo "$(date) - Set fan speed to $speed (PWM), Current fan speed: $(pigs gdc $FAN_PIN) (PWM)" >> $LOG_FILE
}

# Function to get CPU temperature
get_cpu_temp() {
    temp=$(cat /sys/devices/virtual/thermal/thermal_zone0/hwmon0/temp1_input)
    temp_c=$(($temp / 1000)) # Convert to Celsius
    echo $temp_c
    echo "$(date) - CPU Temperature: $temp_c ºC" >> $LOG_FILE
}

# Function to convert PWM to RPM
convert_pwm_to_rpm() {
    local pwm=$1
    local known_pwm=255
    local known_rpm=5000
    local rpm=$(echo "scale=0; ($pwm * $known_rpm) / $known_pwm" | bc)
    echo $rpm
}

# Main loop
while true; do
    temp=$(get_cpu_temp)
    target_speed=$(map_temp_to_pwm $temp)
    rpm=$(convert_pwm_to_rpm $target_speed)
    set_fan_speed $target_speed
    echo "$(date) - Current temperature: $temp ºC, Target fan speed: $target_speed (PWM), Target fan RPM: $rpm RPM" >> $LOG_FILE
    sleep 5 # Check temperature every 5 seconds
done
