#!/bin/sh

# Temperature thresholds
MIN_TEMP=30
MAX_TEMP=70
TEMP_RANGE=$(expr $MAX_TEMP - $MIN_TEMP)
TEMP_STEP=$(expr $TEMP_RANGE \* 10 / 255)
if [ $TEMP_STEP -eq 0 ]; then
    TEMP_STEP=1
fi
echo "MIN_TEMP: $MIN_TEMP, MAX_TEMP: $MAX_TEMP, TEMP_STEP: $TEMP_STEP"

# Define PWM_VALUES array
PWM_VALUES=""
for i in $(seq 0 255); do
    PWM_VALUES="$PWM_VALUES $i"
done

# Log file
LOG_FILE="/sdisk/tslog/fan_control.log"

# Function to map temperature to fan speed PWM value
map_temp_to_pwm() {
    temp=$1
    if [ $temp -lt $MIN_TEMP ]; then
        echo 0
    else
        index=$(expr \( $temp - $MIN_TEMP \) \* 10 / $TEMP_STEP)
        if [ $index -lt 0 ]; then
            index=0
        elif [ $index -ge 255 ]; then
            index=255
        fi
        echo $PWM_VALUES | cut -d ' ' -f $(expr $index + 1)
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
    cpu_temp=$(grep -oP '(?<=Host_CPU_Temperature : \+)[0-9]+(\.[0-9]+)?' /sdisk/tslog/xgs-healthmond.log | tail -n 1)
    echo $cpu_temp
    echo "$(date) - CPU Temperature: $cpu_temp ºC" >> $LOG_FILE
}

# Function to get NPU temperature
get_npu_temp() {
    npu_temp=$(grep -oP '(?<=NPU_CPU_Temperature : \+)[0-9]+(\.[0-9]+)?' /sdisk/tslog/xgs-healthmond.log | tail -n 1)
    echo $npu_temp
    echo "$(date) - NPU Temperature: $npu_temp ºC" >> $LOG_FILE
}

# Function to convert PWM to RPM
convert_pwm_to_rpm() {
    pwm=$1
    known_pwm=255
    known_rpm=5000
    rpm=$(expr \( $pwm \* $known_rpm + 0.5 \) / $known_pwm)
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
    max_temp=$(expr $cpu_temp \> $npu_temp ? $cpu_temp : $npu_temp)  # Use the higher of the two temperatures
    target_speed=$(map_temp_to_pwm $max_temp)
    rpm=$(convert_pwm_to_rpm $target_speed)
    set_fan_speed $target_speed
    echo "$(date) - Current CPU temperature: $cpu_temp ºC, Current NPU temperature: $npu_temp ºC, Target fan speed: $target_speed (PWM), Target fan RPM: $rpm RPM" >> $LOG_FILE
    sleep 5 # Check temperature every 5 seconds
done
