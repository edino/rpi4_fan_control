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
