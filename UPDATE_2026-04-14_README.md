# Raspberry Pi 4 Ultrasonic Fan Control

A lightweight, zero-overhead fan control script for the Raspberry Pi 4. It controls fan speed based on CPU temperature using a GPIO pin (PWM), ensuring silent operation at idle and smooth acoustic transitions under heavy loads.

**Tested Hardware:** GeeekPi Aluminum Heatsink with PWM Controllable Fan (Pi 4 Armor Lite).

## Why This Script is Different (The "Silent" Approach)

Most Raspberry Pi fan scripts rely on heavy external tools or standard electrical frequencies that cause problems. This script is engineered for **maximum low noise and efficiency**:

* **Ultrasonic Frequency (No Coil Whine):** Standard PWM fans run at 800Hz, which creates a high-pitched electronic whine. This script pushes the frequency to 25kHz (25000Hz)—completely outside the range of human hearing.
* **Zero-Overhead Math:** Instead of spawning external calculators like `bc` or `awk` every 5 seconds (which generates unnecessary CPU heat), this script uses pure, native Bash integer arithmetic. It is computationally invisible.
* **Zero-RPM & Kickstart:** Below 45ºC, the fan completely stops to allow the heatsink to work passively. When it needs to start spinning, it sends a brief 0.5-second 100% power "pulse" to overcome the motor's physical friction, allowing it to settle into a whisper-quiet low speed without stalling.
* **Smart Logging:** It only writes to your system logs when the fan speed *actually changes*, protecting your SD card or SSD from unnecessary wear and tear.

## Prerequisites

Before installing, ensure you have the required GPIO tool installed on your Raspberry Pi:

```bash
sudo apt update
sudo apt install pigpiod -y
```

Next, map the GPIO pin by adding an entry to your boot configuration file:

```bash
grep -q "^dtoverlay=gpio-fan,gpiopin=18" /boot/firmware/config.txt || echo "dtoverlay=gpio-fan,gpiopin=18" | sudo tee -a /boot/firmware/config.txt
```

*(Note: Depending on your OS, the config file might be located at `/boot/config.txt` instead).*

Enable the `pigpiod` service so the system can communicate with the GPIO pins:

```bash
sudo systemctl enable --now pigpiod
```

## Installation

### 1. Download the script
Download the control script directly to your local binaries folder:

```bash
sudo curl -vlO [https://raw.githubusercontent.com/edino/rpi4_fan_control/main/rpi4_fan_control.sh](https://raw.githubusercontent.com/edino/rpi4_fan_control/main/rpi4_fan_control.sh) -o /usr/local/bin/rpi4_fan_control.sh
```

### 2. Make it executable

```bash
sudo chmod +x /usr/local/bin/rpi4_fan_control.sh
```

### 3. Create the background service
To make the script run automatically when the Pi boots up, we create a systemd service. Open a new file:

```bash
sudo nano /etc/systemd/system/fan_control.service
```

Paste the following configuration into the file:

```ini
[Unit]
Description=Ultrasonic Fan Control Service
After=network.target pigpiod.service
Requires=pigpiod.service

[Service]
ExecStart=/usr/local/bin/rpi4_fan_control.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Save and exit (`Ctrl + O`, `Enter`, `Ctrl + X`).

### 4. Start and enable the service
Reload the system to recognize the new service, then start it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now fan_control.service
```

## Customizing the Script

If you want to adjust the temperatures at which the fan turns on or reaches maximum speed, you can easily edit the variables at the top of the script:

```bash
sudo nano /usr/local/bin/rpi4_fan_control.sh
```

Look for these lines:
* `MIN_TEMP=45000` (This is 45ºC. Below this, the fan is off).
* `MAX_TEMP=75000` (This is 75ºC. At or above this, the fan is at 100%).
* `MIN_PWM=70` (The lowest power sent to the fan. Do not set this too low, or the fan motor won't have enough power to spin).

## Monitoring the Fan

Because the script uses smart logging, you won't be spammed with log entries. You can check the history of your fan's speed changes by reading the log file:

```bash
cat /var/log/fan_control.log
```

## License
This project is licensed under the GPL-3.0 license. See the LICENSE file for details.
