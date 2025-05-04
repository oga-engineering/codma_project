# CODMA PROJECT
This is the top level of the CODMA project. It contains the rtl and the testbench components. In its current status, the project requires scripts to run the tests in the evaluation testbench easier in an open-source simulator.

This project began as a masters design project in 2023. It has been used to improve SystemVerilog coding skills and serves as an example of basic rtl coding abilities.

## Requirements
- Verilator for cocotb testbenches (under dev)
- Simulator for functional testbenches (requires maintenance)
- Simulator for UVM testbenches (under dev)

## Verilator Build
To build the verilator objects, cd into the scripts submodule and run "python3 build_verilator.py".

## To Do:
- Import the UVM testbench as a submodule 
- Use a BFM style testbench in SystemVerilog
- Use a BFM style testbench in VHDL using OSVVM
- Setup scripts to run tests using open source simulation software, starting with the BFM based tests
- Cleanup project structure
