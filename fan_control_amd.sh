#!/bin/sh

# Log file
LOG_FILE="/sdisk/tslog/fan_control.log"

# Temperature thresholds
MIN_TEMP=30
MAX_TEMP=70
TEMP_RANGE=$((MAX_TEMP - MIN_TEMP))
TEMP_STEP=$((TEMP_RANGE * 100 / 255))
if [ "$TEMP_STEP" -eq 0 ]; then
    TEMP_STEP=1
fi
echo "MIN_TEMP: $((MIN_TEMP / 100)).$((MIN_TEMP % 100)), MAX_TEMP: $((MAX_TEMP / 100)).$((MAX_TEMP % 100)), TEMP_STEP: $((TEMP_STEP / 100)).$((TEMP_STEP % 100))"

# Define PWM_VALUES array
PWM_VALUES=""
i=0
while [ $i -le 255 ]; do
    PWM_VALUES="$PWM_VALUES $i"
    i=$((i + 1))
done

# Function to map temperature to fan speed PWM value
map_temp_to_pwm() {
    local temp="$1"
    if [ "$temp" -lt "$MIN_TEMP" ]; then
        echo 0
    else
        local index=$(( (temp - MIN_TEMP) * 255 / TEMP_RANGE ))
        if [ "$index" -lt 0 ]; then
            index=0
        elif [ "$index" -ge 255 ]; then
            index=255
        fi
        echo "${PWM_VALUES[index]}"
    fi
}

# Function to set fan speed
set_fan_speed() {
    local speed="$1"
    echo "$speed" > /sys/devices/platform/nct6775.2608/hwmon/hwmon0/pwm2
    if [ $? -ne 0 ]; then
        echo "$(date) - Failed to set fan speed to $speed (PWM)" >> "$LOG_FILE"
    else
        echo "$(date) - Set fan speed to $speed (PWM), Current fan speed: $(cat /sys/devices/platform/nct6775.2608/hwmon/hwmon0/pwm2) (PWM)" >> "$LOG_FILE"
    fi
}

# Function to get CPU temperature
get_cpu_temp() {
    local cpu_temp
    cpu_temp=$(grep -m 1 'Host_CPU_Temperature : ' /sdisk/tslog/xgs-healthmond.log | awk '{print $NF}' | sed 's/.*: +//;s/ Degrees.*//')
    if [ -n "$cpu_temp" ] && [ "$cpu_temp" -eq "$cpu_temp" ]; then
        echo "$cpu_temp"
        echo "$(date) - CPU Temperature: $((cpu_temp / 100)).$((cpu_temp % 100)) ºC" >> "$LOG_FILE"
    else
        echo "Error: Unable to retrieve or invalid CPU temperature" >&2
    fi
}

# Function to get NPU temperature
get_npu_temp() {
    local npu_temp
    npu_temp=$(grep -m 1 'NPU_CPU_Temperature : ' /sdisk/tslog/xgs-healthmond.log | awk '{print $NF}' | sed 's/.*: +//;s/ Degrees.*//')
    if [ -n "$npu_temp" ] && [ "$npu_temp" -eq "$npu_temp" ]; then
        echo "$npu_temp"
        echo "$(date) - NPU Temperature: $((npu_temp / 100)).$((npu_temp % 100)) ºC" >> "$LOG_FILE"
    else
        echo "Error: Unable to retrieve or invalid NPU temperature" >&2
    fi
}

# Function to convert PWM to RPM with maximum RPM limit
convert_pwm_to_rpm() {
    local pwm="$1"
    local max_pwm=255
    local max_rpm=5000
    local scaled_pwm=$((pwm * max_rpm / max_pwm))
    local rpm=$((scaled_pwm < max_rpm ? scaled_pwm : max_rpm))
    echo "$rpm"
}

# Check if the log file exists and is writable
if [ ! -f "$LOG_FILE" ]; then
    echo "$(date) - Log file $LOG_FILE not found, creating it" >> "$LOG_FILE"
    touch "$LOG_FILE"
fi
if [ ! -w "$LOG_FILE" ]; then
    echo "$(date) - Log file $LOG_FILE is not writable" >> "$LOG_FILE"
    exit 1
fi

# Main loop
while true; do
    cpu_temp=$(get_cpu_temp)
    npu_temp=$(get_npu_temp)
    max_temp=$(( cpu_temp > npu_temp ? cpu_temp : npu_temp ))  # Use the higher of the two temperatures
    target_speed=$(map_temp_to_pwm "$max_temp")
    rpm=$(convert_pwm_to_rpm "$target_speed")
    set_fan_speed "$target_speed"
    echo "$(date) - Current CPU temperature: $((cpu_temp / 100)).$((cpu_temp % 100)) ºC, Current NPU temperature: $((npu_temp / 100)).$((npu_temp % 100)) ºC, Target fan speed: $target_speed (PWM), Target fan RPM: $rpm RPM" >> "$LOG_FILE"
    sleep 5 # Check temperature every 5 seconds
done
