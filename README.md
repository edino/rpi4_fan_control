**Raspberry Pi 4 Fan Control**

**The FAN tested with this script is the one listed below:**

GeeekPi Aluminum Heatsink with PWM Controllable Fan for Raspberry Pi 4, Pi 4 Armor Lite Heatsink with PWM Speed Control Fan for Raspberry Pi 4 Model B
https://www.amazon.ca/GeeekPi-Raspberry-Aluminum-Heatsink-Controllable/dp/B091L1XKL6

Control fan speed based on CPU temperature using GPIO pin. Temp range 30-70°C, adjusting PWM values.

**Purpose**

This script controls the fan speed of a Raspberry Pi 4 based on the CPU temperature. It defines temperature thresholds and adjusts the PWM values to set the fan speed accordingly. The script continuously monitors the CPU temperature and adjusts the fan speed to maintain it within the specified range, aiming to provide effective cooling while minimizing noise.

**Prerequisites**

apt install pigpiod bc lm-sensors cpufrequtils -y

Add GPI18 entry at config.txt file: grep -q "^dtoverlay=gpio-fan,gpiopin=18" /boot/firmware/config.txt || echo "dtoverlay=gpio-fan,gpiopin=18" | sudo tee -a /boot/firmware/config.txt

(the config.txt file could be located also at /boot/config.txt)

Enable pigs service sudo systemctl enable --now pigpiod && sudo systemctl start --now pigpiod

Download the script using: sudo curl -vlO https://raw.githubusercontent.com/edino/rpi4_fan_control/main/rpi4_fan_control.sh -o /usr/local/bin/rpi4_fan_control.sh

To run this script as a system service, follow these steps:

Ensure the script is executable: sudo chmod +x /usr/local/bin/rpi4_fan_control.sh

Create a systemd service unit file:

Create a new unit file: sudo nano /etc/systemd/system/fan_control.service

Add the following content to the file (replace /usr/local/bin/fan_control.sh with the actual path to your script):

        [Unit]
        Description=Fan Control Service
        After=network.target

        [Service]
        ExecStart=/usr/local/bin/rpi4_fan_control.sh
        ReadWritePaths=/sys/class/hwmon/
        Restart=always

        [Install]
        WantedBy=multi-user.target

Reload systemd: sudo systemctl daemon-reload

Enable the service to start on boot: sudo systemctl enable --now fan_control.service && sudo systemctl start --now fan_control.service

Check the status of the service: sudo systemctl status fan_control.service

**Usage**

Video displaying the rpi4_fan_control script running as a service.

<div align="center">
      <a href="https://www.youtube.com/embed/Pm1UngPpBKg">
     <img 
      src="https://img.youtube.com/vi/Pm1UngPpBKg/0.jpg" 
      alt="Video displaying the rpi4_fan_control script running as a service." 
      style="width:100%;">
      </a>
    </div>


Clone the repository and follow the steps in the "Prerequisites" section to set up the fan control service. The script will continuously monitor the CPU temperature and adjust the fan speed accordingly.

**License**

This project is licensed under the GPL-3.0 license. See the LICENSE file for details.
