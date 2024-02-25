Raspberry Pi 4 Fan Control

The FAN tested with this script is the one listed below:

[GeeekPi Aluminum Heatsink with PWM Controllable Fan for Raspberry Pi 4, Pi 4 Armor Lite Heatsink with PWM Speed Control Fan for Raspberry Pi 4 Model B](https://www.amazon.ca/GeeekPi-Raspberry-Aluminum-Heatsink-Controllable/dp/B091L1XKL6) 

Control fan speed based on CPU temperature using GPIO pin. Temp range 30-70°C, adjusting PWM values.

Purpose

This script controls the fan speed of a Raspberry Pi 4 based on the CPU temperature. It defines temperature thresholds and adjusts the PWM values to set the fan speed accordingly. The script continuously monitors the CPU temperature and adjusts the fan speed to maintain it within the specified range, aiming to provide effective cooling while minimizing noise.

Prerequisites

apt install pigpiod bc

To run this script as a system service, follow these steps:

Ensure the script is executable: chmod +x /usr/local/bin/rpi4_fan_control.sh

Create a systemd service unit file:

Create a new unit file: sudo nano /etc/systemd/system/rpi4_fan_control.service

Add the following content to the file (replace /usr/local/bin/rpi4_fan_control.sh with the actual path to your script):

        [Unit]
        Description=Fan Control Service
        After=network.target

        [Service]
        ExecStart=/usr/local/bin/rpi4_fan_control.sh
        ReadWritePaths=/sys/class/hwmon/hwmon1/
        Restart=always

        [Install]
        WantedBy=multi-user.target

Reload systemd: sudo systemctl daemon-reload

Enable the service to start on boot: sudo systemctl enable --now fan-control.service

Check the status of the service: sudo systemctl status fan-control.service

Usage

Clone the repository and follow the steps in the "Prerequisites" section to set up the fan control service. The script will continuously monitor the CPU temperature and adjust the fan speed accordingly.
License

This project is licensed under the GPL-3.0 license. See the LICENSE file for details.
