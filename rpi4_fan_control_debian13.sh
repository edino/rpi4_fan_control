#!/bin/bash
# Enhanced rpi4_fan_control.sh - Refactored for Debian 13 (Native Hardware PWM)

LOG_FILE="/var/log/fan_control.log"

# Temperature Thresholds (in milliCelsius)
MIN_TEMP=45000
MAX_TEMP=75000

# PWM Constraints (0-255 scale)
MIN_PWM=70 
MAX_PWM=255

# Native Sysfs PWM Paths
PWM_CHIP="/sys/class/pwm/pwmchip0"
PWM_CHAN="$PWM_CHIP/pwm0"
PWM_PERIOD=40000 # 25kHz in nanoseconds (1/25000 sec = 40,000 ns)

# 1. Initialize Hardware PWM
if [ ! -d "$PWM_CHAN" ]; then
    echo 0 > "$PWM_CHIP/export"
    sleep 1 # Wait for sysfs to map the directory
fi

# Disable temporarily to configure
echo 0 > "$PWM_CHAN/enable"
# Set frequency to 25kHz
echo "$PWM_PERIOD" > "$PWM_CHAN/period"
# Re-enable PWM
echo 1 > "$PWM_CHAN/enable"

previous_speed=0
smoothed_speed=0

# 2. Pure bash to read temp
get_cpu_temp() {
    cat /sys/class/thermal/thermal_zone0/temp
}

log_change() {
    echo "$(date) - $1" >> "$LOG_FILE"
}

log_change "Fan control service started using native hardware PWM at 25kHz."

# Main loop
while true; do
    temp=$(get_cpu_temp)

    # Determine Target PWM using native integer math
    if (( temp <= MIN_TEMP )); then
        target_speed=0
    elif (( temp >= MAX_TEMP )); then
        target_speed=$MAX_PWM
    else
        temp_diff=$(( temp - MIN_TEMP ))
        temp_range=$(( MAX_TEMP - MIN_TEMP ))
        pwm_range=$(( MAX_PWM - MIN_PWM ))
        target_speed=$(( MIN_PWM + (temp_diff * pwm_range / temp_range) ))
    fi

    # Exponential smoothing approximation
    if (( previous_speed == 0 && target_speed > 0 )); then
        # Kickstart pulse to overcome static friction (100% duty cycle)
        echo "$PWM_PERIOD" > "$PWM_CHAN/duty_cycle"
        sleep 0.5
        smoothed_speed=$target_speed
    else
        smoothed_speed=$(( (smoothed_speed * 4 + target_speed) / 5 ))
    fi

    # Limit the maximum speed change per loop
    speed_diff=$(( smoothed_speed - previous_speed ))
    if (( speed_diff > 5 )); then
        smoothed_speed=$(( previous_speed + 5 ))
    elif (( speed_diff < -5 )); then
        smoothed_speed=$(( previous_speed - 5 ))
    fi

    # 3. Apply changes and log ONLY if the speed has shifted
    if (( smoothed_speed != previous_speed )); then
        # Convert 0-255 scale to nanosecond duty cycle required by sysfs
        duty_ns=$(( smoothed_speed * PWM_PERIOD / 255 ))
        echo "$duty_ns" > "$PWM_CHAN/duty_cycle"

        temp_c=$(( temp / 1000 ))
        log_change "Temp: ${temp_c}ºC | Fan speed adjusted to $smoothed_speed PWM"

        previous_speed=$smoothed_speed
    fi

    sleep 5
done
