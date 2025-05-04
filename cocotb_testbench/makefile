# Makefile

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

RTL_DIR = $(PWD)/../rtl

VERILOG_SOURCES += $(RTL_DIR)/ip_codma_pkg.sv $(RTL_DIR)/ip_codma_interfaces_verilator.sv  $(RTL_DIR)/ip_codma_main_machine.sv  $(RTL_DIR)/ip_codma_rd_machine.sv  $(RTL_DIR)/ip_codma_wr_machine.sv $(RTL_DIR)/ip_codma_top.sv ip_codma_wrapper.sv
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = ip_codma_wrapper

# MODULE is the basename of the Python test file
MODULE = freerun_testbench

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim