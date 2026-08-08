markdown
# Raspberry Pi 4 Fan Control

**The FAN tested with this script is the one listed below:**
GeeekPi Aluminum Heatsink with PWM Controllable Fan for Raspberry Pi 4, Pi 4 Armor Lite Heatsink with PWM Speed Control Fan for Raspberry Pi 4 Model B
https://www.amazon.ca/GeeekPi-Raspberry-Aluminum-Heatsink-Controllable/dp/B091L1XKL6

Control fan speed based on CPU temperature using a GPIO pin. Temp range 45-75°C, adjusting PWM values for silent, effective cooling.

## Purpose
This script controls the fan speed of a Raspberry Pi 4 based on the CPU temperature. It defines temperature thresholds and adjusts the PWM values to set the fan speed accordingly. The script continuously monitors the CPU temperature and adjusts the fan speed to maintain it within the specified range, aiming to provide effective cooling while minimizing motor noise.

## Installation

Due to security changes in newer Linux kernels, GPIO hardware access has changed. Please choose the installation method that matches your operating system version.


### Option A: Modern Systems (Debian 12 Bookworm, Debian 13 Trixie & newer)
*This version uses the Linux kernel's native hardware PWM interface. It requires zero external software packages and prevents kernel conflicts.*

*(Note: You must reboot your Raspberry Pi after this step for the hardware PWM chip to initialize).*

**1. Configure the Native PWM Overlay:**
Add the hardware PWM entry to your config file:
```bash
grep -q "^dtoverlay=pwm,pin=18,func=2" /boot/firmware/config.txt || echo "dtoverlay=pwm,pin=18,func=2" | sudo tee -a /boot/firmware/config.txt

(Note: You must reboot your Raspberry Pi after this step for the hardware PWM chip to initialize).

```

**2. Download and prepare the script:**

```bash
sudo curl -vL https://raw.githubusercontent.com/edino/rpi4_fan_control/main/rpi4_fan_control_debian13.sh -o /usr/local/bin/rpi4_fan_control.sh
sudo chmod +x /usr/local/bin/rpi4_fan_control.sh

```

**3. Create the systemd service:**

```bash
sudo nano /etc/systemd/system/fan_control.service

```

Add the following content:

```ini
[Unit]
Description=Fan Control Service (Native PWM)
After=network.target

[Service]
ExecStart=/usr/local/bin/rpi4_fan_control.sh
ReadWritePaths=/sys/class/pwm/ /sys/devices/platform/soc/
Restart=always

[Install]
WantedBy=multi-user.target

```

**4. Enable and start the service:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now fan_control.service
sudo systemctl status fan_control.service

```

---

### Option B: Legacy Systems (Debian 11 Bullseye & older)

*This version uses the legacy `pigpiod` daemon. Use this only on older kernels.*

**1. Install Prerequisites:**

```bash
sudo apt install pigpiod bc lm-sensors cpufrequtils -y

```

**2. Configure the GPIO Overlay:**

```bash
grep -q "^dtoverlay=gpio-fan,gpiopin=18" /boot/firmware/config.txt || echo "dtoverlay=gpio-fan,gpiopin=18" | sudo tee -a /boot/firmware/config.txt

```

*(The config.txt file could also be located at `/boot/config.txt` on older systems)*

**3. Enable the pigs service:**

```bash
sudo systemctl enable --now pigpiod

```

**4. Download and prepare the script:**

```bash
sudo curl -vL https://raw.githubusercontent.com/edino/rpi4_fan_control/main/rpi4_fan_control_debian12_and_older.sh -o /usr/local/bin/rpi4_fan_control.sh
sudo chmod +x /usr/local/bin/rpi4_fan_control.sh

```

**5. Create the systemd service:**

```bash
sudo nano /etc/systemd/system/fan_control.service

```

Add the following content:

```ini
[Unit]
Description=Fan Control Service (Legacy)
After=network.target

[Service]
ExecStart=/usr/local/bin/rpi4_fan_control.sh
ReadWritePaths=/sys/class/hwmon/
Restart=always

[Install]
WantedBy=multi-user.target

```

**6. Enable and start the service:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now fan_control.service
sudo systemctl status fan_control.service

```

---

## Usage

Clone the repository and follow the steps in the Installation section to set up the fan control service. The script will continuously monitor the CPU temperature and dynamically adjust the fan speed.

Video displaying the rpi4_fan_control script running as a service:
https://www.youtube.com/embed/Pm1UngPpBKg

## License

This project is licensed under the GPL-3.0 license. See the LICENSE file for details.
