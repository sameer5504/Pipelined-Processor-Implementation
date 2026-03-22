# 🧠 32-bit Pipelined RISC Processor (SystemVerilog)

This project presents the design and verification of a **32-bit pipelined RISC processor** implemented in SystemVerilog. The processor follows a classic **5-stage pipeline architecture** and supports a custom instruction set with arithmetic, logical, memory, and control-flow operations.

---

## 📌 Project Overview

The processor is designed to execute full programs using a **pipelined datapath**, improving performance through instruction-level parallelism.

Key features:
- 5-stage pipeline: IF, ID, EX, MEM, WB
- 16 general-purpose registers (32-bit)
- Separate instruction and data memory
- Custom ISA with arithmetic, logic, memory, and branching instructions
- Fully verified using simulation and testbench

---

## ⚙️ Architecture

### 🧩 Pipeline Stages

1. **Instruction Fetch (IF)**  
   Fetch instruction using Program Counter (PC)

2. **Instruction Decode (ID)**  
   Decode instruction, read registers, generate control signals

3. **Execute (EX)**  
   Perform ALU operations and evaluate branches

4. **Memory Access (MEM)**  
   Read/write data memory

5. **Write Back (WB)**  
   Write results to register file

Each stage is separated by pipeline registers to enable parallel execution :contentReference[oaicite:1]{index=1}

---

## 🧠 Instruction Set (ISA)

The processor supports:

### Arithmetic & Logical
- ADD, SUB, ADDI, CMP
- OR, ORI

### Memory Operations
- LW, SW
- LDW, SDW (multi-cycle operations)

### Control Flow
- BZ, BGZ, BLZ (conditional branches)
- J, JR (jumps)
- CLL (function call)

---

## ⚠️ Hazard Handling

To ensure correct execution in a pipelined environment:

- ✅ **Data Hazards**
  - Forwarding (bypassing)
  - Stall insertion (load-use hazards)

- ✅ **Control Hazards**
  - Branch/jump handling
  - Pipeline flushing

- ✅ **Structural Hazards**
  - Managed through pipeline control logic

These mechanisms ensure correct instruction execution without data corruption :contentReference[oaicite:2]{index=2}

---

## 🔁 Forwarding & Stalling

The design includes a **Forwarding and Stall Unit**:

- Forwards data from EX/MEM/WB stages to avoid delays
- Detects load-use hazards and inserts pipeline bubbles
- Maintains pipeline efficiency while preserving correctness

---

## 🧪 Verification

A comprehensive **simulation-based verification strategy** was implemented:

- Custom SystemVerilog testbench
- Multiple test programs covering all instructions
- Cycle-by-cycle validation of processor behavior
- Waveform analysis for debugging and correctness

### ✅ Results:
- All instructions executed correctly
- Correct handling of hazards and control flow
- Stable pipeline operation across all test cases :contentReference[oaicite:3]{index=3}

---

## 📁 Project Structure
├── design.sv # Top-level processor
├── datapath.sv # Pipeline datapath
├── controlpath.sv # Control logic
├── buildingblocks.sv # Supporting modules
├── testbench.sv # Verification testbench
├── memfile.dat # Instruction/data memory initialization
├── ruledef.txt # Instruction rules/config
├── ArchProjectReport.pdf# Full project report 


---

## 🛠️ Tools Used

- SystemVerilog (RTL Design)
- ModelSim / EDA Playground (Simulation)
- Git & GitHub (Version Control)

---

## 🎯 Key Learning Outcomes

- Pipeline processor design
- Hazard detection and resolution
- Datapath and control path separation
- ISA design and implementation
- RTL verification using testbenches
- Performance-oriented digital design

---

## 👥 Team Members

- Samir Ali 
- Ibrahim Al Ardah   
- Maen Foqaha  

---

