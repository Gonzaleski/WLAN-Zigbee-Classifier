# WLAN and Zigbee Signals Classification Using Artificial Intelligence 📻🛜📶

## Table of Contents
- [Project Overview](#project-overview)
  - [YouTube Link](#youtube-link)
- [Hardware](#hardware)
- [Installation and Usage](#installation-and-usage)
  - [Prerequisites](#prerequisites)
  - [Steps](#steps)
- [References](#references)

## **Project Overview**

The 2.4 GHz ISM band is a busy place, with protocols like Wi-Fi and Zigbee constantly vying for space. In environments like smart homes, industrial IoT, or crowded offices, distinguishing between these signals can be a significant challenge.

This project addresses that problem by developing a lightweight, AI-based classifier that identifies Zigbee and Wi-Fi signals from spectrogram images. Built with MATLAB and deep learning, the system classifies time-frequency spectrograms into three categories: Zigbee, WLAN, and Background. The solution supports both synthetic signal generation and live signal classification using an ADALM-PLUTO SDR.

This project is designed as part of the [Mathworks AI Challenge](https://uk.mathworks.com/academia/students/competitions/student-challenge/ai-challenge.html).


### **YouTube Link**

[![Link to the YouTube Video](https://img.youtube.com/vi/7oP_TmdXER8/0.jpg)](https://www.youtube.com/watch?v=7oP_TmdXER8)

## **Hardware**  

- [ADALM-PLUTO Software Defined Radio (SDR)](https://www.mouser.co.uk/ProductDetail/Analog-Devices/ADALM-PLUTO?qs=xbccQsLEe0ffoUoi%2FjfIWA%3D%3D&srsltid=AfmBOopmZ69ZNWqMXb250HqwJH8mDjs4Z5lK6xoUCLQz-2SmXdFxUKyD)

## **Installation and Usage**

### **Prerequisites**

### **Steps**
1. Clone the repository:
   ```bash
   git clone https://github.com/Gonzaleski/WLAN-Zigbee-Classifier.git
   ```

2. Change the directory:
   ```bash
   cd WLAN-Zigbee-Classifier
   ```

3. Open MATLAB
   
4. Generate the training data:
   - Go to scripts/dataGeneration
   - In MATLAB, run `generateData.m`

5. Train the model:
   - Go to scripts/training
   - In MATLAB, run `trainModel.m`
  
6. Connect the SDR to the laptop

7. Initialize the SDR:
   - Go to scripts/testing
   - In MATLAB, run `initializeSDR.m`

8. Run the test and see the results:
   - Go to scripts/testing
   - In MATLAB, run `testWithSDR.m`

## **References**
