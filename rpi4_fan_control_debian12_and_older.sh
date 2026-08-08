#!/bin/bash

# BuildDate: 17:44 WEST 2026-04-14

# Enhanced rpi4_fan_control.sh - Optimized for Low Noise and Zero-Overhead

FAN_PIN=18
LOG_FILE="/var/log/fan_control.log"

# Temperature Thresholds (in milliCelsius for native bash math)
MIN_TEMP=45000
MAX_TEMP=75000

# PWM Constraints
MIN_PWM=70  # Minimum stable PWM to prevent motor stalling/clicking
MAX_PWM=255

# 1. Eliminate Motor Whine: Set PWM frequency to 25kHz (ultrasonic)
pigs pfs $FAN_PIN 25000

previous_speed=0
smoothed_speed=0

# 2. Use pure bash to read temp to avoid spawning subshells
get_cpu_temp() {
    cat /sys/devices/virtual/thermal/thermal_zone0/temp
}

log_change() {
    echo "$(date) - $1" >> "$LOG_FILE"
}

log_change "Fan control service started. PWM Frequency optimized to 25kHz."

# Main loop
while true; do
    temp=$(get_cpu_temp)

    # Determine Target PWM using native integer math
    if (( temp <= MIN_TEMP )); then
        target_speed=0
    elif (( temp >= MAX_TEMP )); then
        target_speed=$MAX_PWM
    else
        # Linear interpolation
        temp_diff=$(( temp - MIN_TEMP ))
        temp_range=$(( MAX_TEMP - MIN_TEMP ))
        pwm_range=$(( MAX_PWM - MIN_PWM ))
        target_speed=$(( MIN_PWM + (temp_diff * pwm_range / temp_range) ))
    fi

    # Exponential smoothing approximation (equivalent to a 0.2 factor)
    if (( previous_speed == 0 && target_speed > 0 )); then
        # Kickstart pulse to overcome static friction quietly
        pigs p $FAN_PIN 255
        sleep 0.5
        smoothed_speed=$target_speed
    else
        smoothed_speed=$(( (smoothed_speed * 4 + target_speed) / 5 ))
    fi

    # Limit the maximum speed change per loop (max 5 PWM points)
    speed_diff=$(( smoothed_speed - previous_speed ))
    if (( speed_diff > 5 )); then
        smoothed_speed=$(( previous_speed + 5 ))
    elif (( speed_diff < -5 )); then
        smoothed_speed=$(( previous_speed - 5 ))
    fi

    # 3. Apply changes and log ONLY if the speed has shifted
    if (( smoothed_speed != previous_speed )); then
        pigs p $FAN_PIN "$smoothed_speed"

        # Convert to Celsius for readable logging
        temp_c=$(( temp / 1000 ))
        log_change "Temp: ${temp_c}ºC | Fan speed adjusted to $smoothed_speed PWM"

        previous_speed=$smoothed_speed
    fi

    sleep 5
done
