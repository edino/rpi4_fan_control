#!/bin/bash

# BuildDate: 12:35 PM EST 2024-12-19

# GPIO pin number for fan control
FAN_PIN=18

# Temperature thresholds
MIN_TEMP=45
MAX_TEMP=75
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

# Log file
LOG_FILE="/var/log/fan_control.log"

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

# Function to set fan speed
set_fan_speed() {
    local speed=$1
    local speed_hex=$(printf "%x" $speed)  # Convert speed to hexadecimal
    pigs p $FAN_PIN "0x$speed_hex"
    echo "$(date) - Set fan speed to $speed (PWM), Current fan speed: $(pigs gdc $FAN_PIN) (PWM)" >> $LOG_FILE
}

# Function to get CPU temperature
get_cpu_temp() {
    local temp=$(cat /sys/devices/virtual/thermal/thermal_zone0/temp)
    local temp_c=$(($temp / 1000)) # Convert to Celsius
    echo $temp_c
    echo "$(date) - CPU Temperature: $temp_c ºC" >> $LOG_FILE
}

# Function to convert PWM to RPM
convert_pwm_to_rpm() {
    local pwm=$1
    local known_pwm=255
    local known_rpm=5000
    local rpm=$(echo "scale=0; ($pwm * $known_rpm + 0.5) / $known_pwm" | bc)
    echo $rpm
}
#This script includes adjustments for smoother fan speed changes, optimized PWM range, and hysteresis-like behaviour to reduce noise levels. Adjust the smoothing_factor variable to control the speed of fan speed changes. Lower values will result in slower changes and potentially lower noise levels.
# Smoothing and transition settings
previous_speed=0
smoothed_speed=0.0
smoothing_factor=0.2  # Adjust to a lower value for smoother changes
max_change_per_loop=5  # Limit the maximum change per loop to avoid abrupt transitions

# Main loop
while true; do
    temp=$(get_cpu_temp)
    target_speed=$(map_temp_to_pwm $temp)

    # Smooth out fan speed changes using exponential smoothing
    smoothed_speed=$(echo "scale=1; $smoothed_speed * (1 - $smoothing_factor) + $target_speed * $smoothing_factor" | bc)
    smoothed_speed_int=$(echo "scale=0; $smoothed_speed / 1" | bc)

    # Limit the maximum speed change to prevent abrupt changes
    speed_diff=$((smoothed_speed_int - previous_speed))
    if ((speed_diff > max_change_per_loop)); then
        smoothed_speed_int=$((previous_speed + max_change_per_loop))
    elif ((speed_diff < -max_change_per_loop)); then
        smoothed_speed_int=$((previous_speed - max_change_per_loop))
    fi

    # Set the fan speed with the smoothed value
    set_fan_speed $smoothed_speed_int
    rpm=$(convert_pwm_to_rpm $smoothed_speed_int)

    echo "$(date) - Current temperature: $temp ºC, Target fan speed: $smoothed_speed_int (PWM), Target fan RPM: $rpm RPM" >> $LOG_FILE

    # Save the current speed as the previous speed for next iteration
    previous_speed=$smoothed_speed_int

    sleep 5 # Check temperature every 5 seconds
done
