from custom_functions import *

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

#This is a simple testbench to run the clock and active low reset.
#It was used to learn the very basics of cocotb and run any serous evaluation of the RTL.

@cocotb.test()
async def my_first_test(dut):
    # Initial values
    await startup_values(dut)

    # Cocotb in-built clock generator
    cocotb.start_soon(Clock(dut.clk_i,10, units='ns').start())

    # Wait for 5 clocks and send a reset pulse
    ClockCycles(dut.clk_i,5,rising=True)
    
    # Send a 10 ns reset
    await send_timed_rst(dut,10)


