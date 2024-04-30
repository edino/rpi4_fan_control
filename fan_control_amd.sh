#!/bin/sh

# Temperature thresholds
MIN_TEMP=3000
MAX_TEMP=7000
TEMP_RANGE=$((MAX_TEMP - MIN_TEMP))
TEMP_STEP=$((TEMP_RANGE * 100 / 255))
if [ "$TEMP_STEP" -eq 0 ]; then
    TEMP_STEP=1
fi
echo "MIN_TEMP: $(printf "%0.2f" $(echo "scale=2; $MIN_TEMP / 100" | bc)), MAX_TEMP: $(printf "%0.2f" $(echo "scale=2; $MAX_TEMP / 100" | bc)), TEMP_STEP: $(printf "%0.2f" $(echo "scale=2; $TEMP_STEP / 100" | bc))"

# Define PWM_VALUES array
PWM_VALUES=""
for i in $(seq 0 255); do
    PWM_VALUES="$PWM_VALUES $i"
done

# Log file
LOG_FILE="/sdisk/tslog/fan_control.log"

# Function to map temperature to fan speed PWM value
map_temp_to_pwm() {
    local temp=$1
    if [ "$temp" -lt "$MIN_TEMP" ]; then
        echo 0
    else
        local index=$(( (temp - MIN_TEMP) * 100 / TEMP_STEP ))
        if [ "$index" -lt 0 ]; then
            index=0
        elif [ "$index" -ge 255 ]; then
            index=255
        fi
        echo "${PWM_VALUES[$index]}"
    fi
}

# Function to set fan speed
set_fan_speed() {
    speed=$1
    echo $speed > /sys/devices/platform/nct6775.2608/hwmon/hwmon0/pwm2
    if [ $? -ne 0 ]; then
        echo "$(date) - Failed to set fan speed to $speed (PWM)" >> $LOG_FILE
    else
        echo "$(date) - Set fan speed to $speed (PWM), Current fan speed: $(cat /sys/devices/platform/nct6775.2608/hwmon/hwmon0/pwm2) (PWM)" >> $LOG_FILE
    fi
}

# Function to get CPU temperature
get_cpu_temp() {
    cpu_temp=$(grep 'Host_CPU_Temperature : ' /sdisk/tslog/xgs-healthmond.log | tail -n 1 | sed 's/.*: +//;s/ Degrees.*//')
    echo $cpu_temp
    echo "$(date) - CPU Temperature: $(printf "%0.2f" $(echo "scale=2; $cpu_temp / 100" | bc)) ºC" >> $LOG_FILE
}

# Function to get NPU temperature
get_npu_temp() {
    npu_temp=$(grep 'NPU_CPU_Temperature : ' /sdisk/tslog/xgs-healthmond.log | tail -n 1 | sed 's/.*: +//;s/ Degrees.*//')
    echo $npu_temp
    echo "$(date) - NPU Temperature: $(printf "%0.2f" $(echo "scale=2; $npu_temp / 100" | bc)) ºC" >> $LOG_FILE
}

# Function to convert PWM to RPM
convert_pwm_to_rpm() {
    pwm=$1
    known_pwm=255
    known_rpm=5000
    rpm=$(( (pwm * known_rpm + 50) / 100 ))
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
    max_temp=$(( cpu_temp > npu_temp ? cpu_temp : npu_temp ))  # Use the higher of the two temperatures
    target_speed=$(map_temp_to_pwm $max_temp)
    rpm=$(convert_pwm_to_rpm $target_speed)
    set_fan_speed $target_speed
    echo "$(date) - Current CPU temperature: $(printf "%0.2f" $(echo "scale=2; $cpu_temp / 100" | bc)) ºC, Current NPU temperature: $(printf "%0.2f" $(echo "scale=2; $npu_temp / 100" | bc)) ºC, Target fan speed: $target_speed (PWM), Target fan RPM: $rpm RPM" >> $LOG_FILE
    sleep 5 # Check temperature every 5 seconds
done
