from cocotb.triggers import Timer
from cocotb.binary import BinaryValue

#This is a simple testbench to run the clock and active low reset.
#It was used to learn the very basics of cocotb and run any serous evaluation of the RTL.


async def startup_values(codma):
    # Clocks and resets
    codma.clk_i.value       = 0
    codma.reset_n_i.value   = 1

    # CPU interface
    codma.start.value             =   0
    codma.stop.value              =   0
    codma.status_pointer.value    =   0
    codma.task_pointer.value      =   0

    # Memory interface
    codma.grant.value 	    = 0
    codma.read_data.value   = 0
    codma.read_valid.value	= 0
    codma.error.value       = 0

    # Wait 1ns in simulation time
    await Timer(1,units='ns')

async def send_timed_rst(codma, time_ns=5):
    codma.reset_n_i.value = 0
    await Timer(time_ns,units='ns')
    codma.reset_n_i.value = 1