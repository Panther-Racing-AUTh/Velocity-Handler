# ESP32 C3 Motorcycle RPM Monitor App

This repository contains a Flutter app that connects to an ESP32-C3 microcontroller over Wi-Fi to monitor real-time motorcycle RPM. The app categorizes RPM values into four modes, making it ideal for tracking engine performance and ride behavior.

---

## Features

- **Wi-Fi Connectivity**: Connects to the ESP32-C3 over Wi-Fi.
- **Real-Time RPM Display**: Continuously monitors and updates the RPM.
- **Four Modes Based on RPM**:
  - **Idle**: 0-1500 RPM
  - **Economy**: 1501-4000 RPM
  - **Sport**: 4001-7000 RPM
  - **Overdrive**: 7001+ RPM
- **Customizable RPM Ranges**: Easily modify ranges to fit your needs.

---

## Prerequisites

### Hardware
- ESP32-C3 microcontroller
- Motorcycle RPM signal output (or sensor setup)
- Wi-Fi-enabled smartphone or tablet

### Software
- Flutter SDK (latest stable version)
- Arduino IDE for ESP32 firmware

---

## Setup

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/esp32-c3-motorcycle-rpm-monitor.git
cd esp32-c3-motorcycle-rpm-monitor
