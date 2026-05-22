# MATLAB Synth Studio 🎹

A MATLAB-based digital synthesizer developed using core signal processing and control system concepts. The project features an interactive dark-themed graphical user interface capable of generating and controlling multiple waveforms in real time without relying on additional MATLAB toolboxes.

The synthesizer combines waveform generation, ADSR envelope shaping, and real-time audio visualization to create a standalone audio synthesis environment entirely within base MATLAB.

---

# ✨ Features

- Interactive dark-themed synthesizer interface
- Multiple waveform generation support:
  - Sine
  - Square
  - Sawtooth
  - Triangle
- ADSR envelope control for sound shaping
- Real-time waveform visualization using a live oscilloscope
- Built-in melody sequencer and playback system
- Manual note hold and release controls
- Standalone implementation without external MATLAB toolboxes
- Real-time audio playback and signal manipulation

---

# 🧠 Project Overview

This project focuses on implementing a complete software-based synthesizer using MATLAB fundamentals and control system principles. The system generates audio signals mathematically and processes them dynamically to simulate real synthesizer behavior.

Waveforms are generated using mathematical models, while envelope shaping controls the amplitude characteristics of the generated sound. The GUI provides real-time interaction for waveform selection, parameter adjustment, and audio monitoring.

The project demonstrates concepts from:
- Signal Processing
- Control Systems
- Audio Synthesis
- Real-Time System Simulation
- Human-Machine Interface Design

---

# 🎛️ Functional Modules

## 🎵 Waveform Generator

Generates multiple periodic waveforms mathematically using MATLAB functions:
- Sine wave
- Square wave
- Triangle wave
- Sawtooth wave

---

## 📈 ADSR Envelope Controller

Implements:
- Attack
- Decay
- Sustain
- Release

These parameters help shape the dynamic characteristics of generated audio signals similar to real synthesizers.

---

## 📊 Real-Time Oscilloscope

- Live waveform monitoring
- Real-time visualization of generated audio signals
- Dynamic signal plotting during playback

---

## 🎼 Melody Sequencer

Includes programmed melody playback functionality capable of reproducing predefined musical sequences and note patterns.

---

## 🎚️ Manual Playback Controls

- Hold Note functionality
- Release Note control
- Interactive GUI-based testing environment

---

# 💻 Technologies Used

| Technology | Purpose |
|---|---|
| MATLAB | Core development platform |
| MATLAB GUI Components | Interface design |
| Audio Processing Functions | Real-time sound generation |
| Timer Functions | Fixed-rate execution control |

---

# ⚙️ Technical Implementation

The synthesizer operates through a real-time processing loop controlled using MATLAB timer functions. Audio samples are generated dynamically and streamed continuously for playback.

Waveform synthesis for sawtooth and triangle signals is implemented manually using mathematical expressions instead of relying on external signal processing libraries, ensuring compatibility across multiple MATLAB versions.

The project also incorporates:
- Real-time signal buffering
- Dynamic waveform rendering
- Software-based oscillator control
- Event-driven GUI interaction

---

# 🚀 How to Run

## 1️⃣ Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/matlab-synth-studio.git
