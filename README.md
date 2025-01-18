# ESP32 C3 Motorcycle RPM Monitor App

This repository contains a Flutter app that connects to an ESP32-C3 microcontroller over Wi-Fi to monitor real-time motorcycle RPM. The app categorizes RPM values into four modes, making it ideal for tracking engine performance and ride behavior.

---

## Features

- **Wi-Fi Connectivity**: Connects to the ESP32-C3 over Wi-Fi.
- **Real-Time RPM Display**: Continuously monitors and updates the RPM.
- **Four Modes Based on RPM**
- **Customizable RPM Ranges**: Easily modify ranges to fit your needs.
- **Responsive UI**: Optimized for both Android and iOS devices.

---

## Prerequisites

### Hardware
- **ESP32-C3 Microcontroller**: Configured to read motorcycle RPM.
- **RPM Signal Source**: Ensure your motorcycle provides an accessible RPM signal (e.g., from the tachometer output or engine management system).
- **Power Source**: USB power for ESP32-C3.

### Software
- **Flutter SDK**: Install the latest stable version ([Flutter installation guide](https://flutter.dev/docs/get-started/install)).
- **Arduino IDE**: For programming the ESP32-C3 ([Arduino installation guide](https://www.arduino.cc/en/software)).
- **ESP32 Board Manager**: Add the ESP32 core to Arduino IDE ([ESP32 setup guide](https://github.com/espressif/arduino-esp32)).

---

## Setup

### 1. Clone the Repository
- **ESP32**:
git clone https://github.com/Panther-Racing-AUTh/velocity-stack.git

- **Flutter App**:
git clone https://github.com/Panther-Racing-AUTh/Velocity-Handler.git


