#!/bin/sh

# Temperature thresholds
MIN_TEMP=30
MAX_TEMP=70
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
LOG_FILE="/sdisk/tslog/fan_control.log"

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
    echo $speed > /sys/devices/platform/nct6775.2608/hwmon/hwmon0/pwm2
    if [ $? -ne 0 ]; then
        echo "$(date) - Failed to set fan speed to $speed (PWM)" >> $LOG_FILE
    else
        echo "$(date) - Set fan speed to $speed (PWM), Current fan speed: $(cat /sys/devices/platform/nct6775.2608/hwmon/hwmon0/pwm2) (PWM)" >> $LOG_FILE
    fi
}

# Function to get CPU temperature
get_cpu_temp() {
    local cpu_temp=$(grep -oP '(?<=Host_CPU_Temperature : \+)[0-9]+(\.[0-9]+)?' /sdisk/tslog/xgs-healthmond.log | tail -n 1)
    echo $cpu_temp
    echo "$(date) - CPU Temperature: $cpu_temp ºC" >> $LOG_FILE
}

# Function to get NPU temperature
get_npu_temp() {    
    local npu_temp=$(grep -oP '(?<=NPU_CPU_Temperature : \+)[0-9]+(\.[0-9]+)?' /sdisk/tslog/xgs-healthmond.log | tail -n 1)
    echo $npu_temp
    echo "$(date) - NPU Temperature: $npu_temp ºC" >> $LOG_FILE
}

# Function to convert PWM to RPM
convert_pwm_to_rpm() {
    local pwm=$1
    local known_pwm=255
    local known_rpm=5000
    local rpm=$(echo "scale=0; ($pwm * $known_rpm + 0.5) / $known_pwm" | bc)
    echo $rpm
}

# Check if the log file exists and is writable
if [ ! -f $LOG_FILE ]; then
    echo "$(date) - Log file $LOG_FILE not found, creating it" >> $LOG_FILE
    touch $LOG_FILE
fi
if [ ! -w $LOG_FILE ]; then
    echo "$(date) - Log file $LOG_FILE is not writable" >> $LOG_FILE
    exit 1
fi

# Main loop
while true; do
    cpu_temp=$(get_cpu_temp)
    npu_temp=$(get_npu_temp)
    max_temp=$((cpu_temp > npu_temp ? cpu_temp : npu_temp))  # Use the higher of the two temperatures
    target_speed=$(map_temp_to_pwm $max_temp)
    rpm=$(convert_pwm_to_rpm $target_speed)
    set_fan_speed $target_speed
    echo "$(date) - Current CPU temperature: $cpu_temp ºC, Current NPU temperature: $npu_temp ºC, Target fan speed: $target_speed (PWM), Target fan RPM: $rpm RPM" >> $LOG_FILE
    sleep 5 # Check temperature every 5 seconds
done
