![NetFlex Logo](logo.jpeg)

# NetFlex - Networked Control Systems Simulation Framework

## 📌 Overview
NetFlex is a **MATLAB-based simulation framework** for **Networked Control Systems (NCS)**. It provides an **object-oriented architecture** to model network-induced effects, e.g., delays, dropouts, while implementing control and observer algorithms in a modular fashion.

This toolbox is built on top of **MATLAB Simulink TrueTime** to enable seamless simulation of communication-constrained control systems.

---

## 🚀 Features
✔ **Object-Oriented Simulation Framework** – Modular and scalable architecture based on MATLAB.  
✔ **Flexible Network Nodes** – Includes delay, dropout, and buffering mechanisms.  
✔ **State Feedback & Observer Implementations** – Supports advanced control strategies.  
✔ **Easily Extendable** – Define new nodes, control laws, and observer mechanisms.  
✔ **Integration with Simulink** – Uses TrueTime blocks for real-time network simulations.  
✔ **Predefined Examples** – Ready-to-use NCS simulation setups.  

---

## 📁 Project Structure

```
NetFlex-Framework/
│── docs/                  # Documentation (user guides, UML diagrams)
│── examples/              # Example simulation scripts
│── framework/             # Main Framework source code
│   │── messages/          # Contains base classes, including abstract classes and utility functions
│   │── models/            # Directory for data models and related classes
│   │── nodes/             # Network node implementations
│   └── utils/             # Helper functions (TrueTime handling, data handling, etc.)
│── tests/                 # Unit tests for framework components
│── data/                  # Example datasets, simulation results
│── .gitignore             # Ignore unnecessary files
│── LICENSE                # License details
└── README.md              # Project overview
```

---

## 🔧 Installation & Setup

### 1️⃣ **Clone the Repository**
```bash
git clone https://github.com/YOUR-USERNAME/NetFlex-Framework.git
cd NetFlex-Framework
```

### 2️⃣ **MATLAB Setup**
Ensure you have:
- MATLAB R2022a+
- Simulink & TrueTime Toolbox installed

### 3️⃣ **Run an Example**
Open MATLAB and run:
```matlab
cd examples
run main.m
```
This will launch a **predefined simulation** of an NCS with delays and dropouts.

---

## TrueTime Patch for MATLAB Compatibility

### Overview

This repository contains a patched version of TrueTime, modified to be compatible with newer MATLAB versions (R2022a and later). The original TrueTime code used the deprecated `mexSetTrapFlag` function, which was removed in MATLAB R2022a. This patch replaces `mexSetTrapFlag` with `mexCallMATLABWithTrap` to ensure compatibility.

### Changes Made

- **Replaced **`` with `mexCallMATLABWithTrap(0, NULL, 0, NULL, "error");` in all affected source files.
- Recompiled TrueTime on **macOS (Apple Silicon)** to ensure compatibility.

### Supported MATLAB Versions

- ✅ MATLAB **R2022a and later** (Tested on R2024b)
- ⚠️ MATLAB **R2020b - R2022a**: Allowed but shows warnings.

### Compilation Instructions

To compile TrueTime on other platforms, follow these steps:

1. Clone the repository:

   ```sh
   git clone https://github.com/your-repo/truetime-patch.git
   cd libs/truetime-2.0
   ```

2. Set up the MATLAB compiler:

   ```matlab
   mex -setup C++
   ```

3. Compile TrueTime:

   ```matlab
   make_truetime
   ```

4. Verify the installation:

   ```matlab
   which ttkernel -all
   which ttnetwork -all
   ```

---

## 🏗️ Object-Oriented Design (UML Overview)
The framework follows a **class-based architecture**, where each network component is implemented as a **MATLAB class**:
  
Detailed UML diagrams are available in `docs/`.

---

## 📜 Contributing
We welcome contributions!  
- To add a feature, **fork the repository**, make changes, and submit a **pull request**.  
- Report issues or feature requests in the **GitHub Issues** section.

---

## 📄 License
NetFlex is released under the **GPL v3**.  
See [LICENSE](LICENSE) for details.

---


