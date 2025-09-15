# RISCV-MatX

A computer engineering project that extends a basic RISC-V processor with custom vector processing capabilities to accelerate matrix multiplication operations.

## Overview

RISCV-MatX demonstrates how custom hardware extensions can dramatically improve performance for matrix operations by adding three custom vector instructions to a standard RISC-V processor. The system achieves a **4.5x speedup** for 4×4 matrix multiplication compared to scalar processing.

## Core Concept

The project extends a RISC-V processor with vector processing capabilities, enabling parallel matrix operations that are much faster than traditional scalar processing. This approach is particularly relevant for AI/ML applications where matrix operations are fundamental.

## Key Technical Components

### Vector Processing Unit
- **Vector Register File (VRF)**: Stores 128-bit wide vector data
- **Vector ALU (VALU)**: Performs parallel element-wise operations
- **Enhanced Memory**: Expanded to 128-bit width for efficient vector access

### Custom Vector Instructions
- **V_LOAD**: Load vectors from memory into vector registers
- **V_STORE**: Store vectors from vector registers to memory  
- **V_MUL**: Perform element-wise vector multiplication

## Performance Results

| Implementation | Clock Cycles | Speedup |
|----------------|--------------|---------|
| Scalar         | 3,200        | 1x      |
| Vector         | 700          | 4.5x    |

The vector implementation achieves significant performance improvement for 4×4 matrix multiplication operations.

## Implementation Details

- **Language**: Verilog HDL
- **Simulation**: ModelSim
- **Hardware**: Prototyped on Altera Cyclone II FPGA
- **Architecture**: Single-cycle (non-pipelined)
- **Matrix Size**: Fixed 4×4 matrices

## Project Structure

```
RISCV-MatX/
├── src/           # Verilog source files
├── testbench/     # Test files and simulations
├── docs/          # Documentation and reports
└── README.md      # This file
```

## Getting Started

### Prerequisites
- ModelSim or compatible Verilog simulator
- Quartus II (for FPGA implementation)
- Basic knowledge of RISC-V architecture and Verilog

### Running Simulations
1. Open ModelSim
2. Load the project files from the `src/` directory
3. Run the testbench files from `testbench/`
4. Observe the performance comparison between scalar and vector implementations

## Educational Value

This project bridges theoretical computer architecture concepts with practical hardware implementation, demonstrating:

- Custom instruction set extensions
- Vector processing principles
- Hardware acceleration techniques
- Performance optimization through parallelism
- FPGA prototyping and verification

## Limitations

- **Fixed Matrix Size**: Only supports 4×4 matrices (educational scope)
- **Single-Cycle Architecture**: Not pipelined for simplicity
- **No Floating-Point Support**: Integer operations only
- **Educational Implementation**: Not optimized for industrial-scale solutions

## Future Enhancements

- Support for variable matrix sizes
- Pipelined architecture implementation
- Floating-point arithmetic support
- More complex vector operations
- Cache optimization for larger datasets

## Contributing

This is an educational project. Feel free to fork and experiment with different optimizations or extensions.

## License

This project is for educational purposes. Please refer to your institution's guidelines for academic use.

---

**Note**: This project demonstrates fundamental concepts in computer architecture and hardware acceleration. The implementation prioritizes educational clarity over industrial optimization.