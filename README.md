# Benchmark Core

**Benchmark Core** is a mobile benchmarking suite built with **Flutter**, **Dart FFI**, and **Native C**. It is designed to stress-test the CPU, GPU, and Memory subsystems of android devices to reveal thermal throttling trends, peak performance, and system stability under sustained load.

## Features

* **Hybrid Architecture:** Combines the UI flexibility of Flutter with the raw performance of native C via Dart FFI.
* **CPU:** Multi-threaded and Single-threaded Matrix Multiplication and recursive Fibonacci sequences.
* **GPU:** Native OpenGL ES 3.0 rendering engine using headless PBuffers.
* **Memory:** Bandwidth (memcpy) and Latency (pointer chasing) tests.
* **Real-Time Analytics:** Interactive charts (`fl_chart`) visualize performance trends over multiple runs.
* **Detailed System Specs:** Automatically detects and displays device specifications.

## Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend/Core:** C
* **Bridge:** Dart FFI 
* **Graphics API:** OpenGL ES 3.0 / EGL 

## Benchmarks in Detail

### 1. CPU Benchmark

Designed to saturate all CPU cores and force maximum power draw.

* **Matrix Multiplication:** Performs 2500x2500 matrix operations in both single-threaded and multi-threaded modes.
* **Fibonacci Sequence:** Recursive calculation (N=45) to test integer arithmetic and branch prediction.
* **Scoring:** Aggregated score based on execution time and throughput.

### 2. GPU Benchmark

A test for mobile GPUs, running completely off-screen.

* **Workload:** Renders 1225 overlapping 3D cubes (35x35 grid) with complex transforms.
* **Overdraw:** `GL_DEPTH_TEST` is **disabled** and `GL_BLEND` is **enabled**, forcing the GPU to process every pixel of every cube.
* **Math Load:** Custom fragment shader performs 1,000 iterations of `sin/cos/sqrt` per pixel.

### 3. Memory Benchmark

Measures the raw speed and latency of the RAM subsystem.

* **Bandwidth:** Repeatedly copies 512MB chunks of memory to measure read/write speed (MB/s).
* **Latency:** Performs 3 million random pointer chase steps to measure average access time (ns).
* **Scoring:** Weighted formula favoring high bandwidth and low latency.

## Screenshots

| Home | CPU | GPU | Memory | Specs |
| :---: | :---: | :---: | :---: | :---: |
| <img src="https://github.com/user-attachments/assets/0266c889-bde7-4d80-b143-2b46198ba161" width="200"> | <img src="https://github.com/user-attachments/assets/ed58ebeb-734c-4671-8ecd-6718c908c58e" width="200"> | <img src="https://github.com/user-attachments/assets/731bcdef-862c-440f-ab1f-e1dbe1ea93cd" width="200"> | <img src="https://github.com/user-attachments/assets/c4480b26-6855-44da-8789-f41983d701cf" width="200"> | <img src="https://github.com/user-attachments/assets/4a551db5-50bf-4c85-9e34-030d4e37c738" width="200"> |

## Installation & Setup

1. **Prerequisites:**
* Flutter SDK (Latest Stable)
* Android NDK (for native C compilation)
* CMake


2. **Clone the Repository:**
```bash
git clone https://github.com/SerbanTudor-Fechete/BenchmarkApp.git
cd benchmark_core
```


3. **Build Native Library:**
Ensure your `CMakeLists.txt` is configured correctly in `/src/` to build the `.so` file.
4. **Run the App:**
```bash
flutter pub get
flutter run 

```
