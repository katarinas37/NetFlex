![NetFlex Logo](logo.png)

# **NetFlex - Networked Control Systems Simulation Framework**

## 📌 **Bridging the Gap between Communication and Control**
NetFlex is a **MATLAB/Simulink-based** simulation framework for **Networked Control Systems (NCS)**, enabling realistic modeling of **network effects** such as **delays, data loss, and packet reordering**. It provides a **modular and scalable** structure, allowing users to define **custom control and observer strategies**, configure network conditions, and simulate various scenarios.

Built on top of **MATLAB Simulink TrueTime**, NetFlex facilitates the simulation of **communication-constrained control systems** in an intuitive and extendable way.

---

## 🚀 **Key Features**
✔ **Object-Oriented Design** – Modular architecture for flexible NCS modeling.  
✔ **Advanced Network Effects** – Supports delays, dropouts, buffering, and reordering.  
✔ **Customizable Control & Observer Strategies** – Implement and test new algorithms easily.  
✔ **Seamless Simulink Integration** – Uses TrueTime blocks for networked control simulations.  
✔ **Predefined Examples** – Includes ready-to-use NCS setups for quick testing.  
✔ **Easily Extendable** – Define new nodes, control laws, and observer mechanisms.  

---

## 📁 Project Structure

```
NetFlex-Framework/
│── docs/                  # Documentation (user guides, UML diagrams)
│── examples/              # Example simulation scripts
│── framework/             # Main Framework source code
│   │── interfaces/        # Contains interface for control and observer strategies 
│   │── messages/          # Contains base classes for data exchange in NCS
│   │── ncs/               # Contains template for defining an example
│   │── nodes/             # Network node implementations
│   │── strategies/        # Different control and observer strategies (easily expandable)
│   └── utils/             # Helper functions (TrueTime handling, data handling, etc.)
│── libs/                  # TrueTime
│   └──  truetime-2.0/      # Contains TrueTime compatible with MATLAB R2022a and later
│── LICENSE                # License details
└── README.md              # Project overview
```

---
## 🏗️ Object-Oriented Design (UML Overview)
The framework follows a **class-based architecture**, where each network component is implemented as a **MATLAB class**:
  
Detailed UML diagrams are available in `docs/`.

---

## TrueTime Patch for MATLAB Compatibility

### Overview

This repository contains a patched version of TrueTime, modified to be compatible with newer MATLAB versions (R2022a and later). 

The original TrueTime code used the deprecated `mexSetTrapFlag` function, which was removed in MATLAB R2022a. This patch replaces `mexSetTrapFlag` with `mexCallMATLABWithTrap` to ensure compatibility. 

### Changes Made

- **Replaced **`` with `mexCallMATLABWithTrap(0, NULL, 0, NULL, "error");` in all affected source files.
- Recompiled TrueTime on **macOS (Apple Silicon)** to ensure compatibility.

### Supported MATLAB Versions

- ✅ MATLAB **R2022a and later** (Tested on R2024b)
- ⚠️ MATLAB **R2020b - R2022a**: Allowed but shows warnings.

If older of MATLAB is used, please download the original version of TrueTime at https://github.com/sfischme/truetime.
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

## 🔧 Installation & Setup

### 1️⃣ **Clone the Repository**
```bash
git clone https://github.com/YOUR-USERNAME/NetFlex-Framework.git
cd NetFlex-Framework
```

### 2️⃣ **MATLAB Setup**
Ensure you have:
- MATLAB 
- Simulink & TrueTime Toolbox installed

### 3️⃣ **Run an Example**
This will launch a **simple predefined simulation** of an NCS with only sensor and controller generating a ramp.
Open MATLAB and change to folder NetFlex. Run:
```bash
run('framework/ncs/main.m')
```
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


