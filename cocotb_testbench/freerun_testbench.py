import cocotb
from cocotb.clock       import Clock
from cocotb.triggers    import RisingEdge, Timer

@cocotb.coroutine
async def free_run(ip_codma_top):
    
    # Create a 10ns period clock on ip_codma_top.clk
    cocotb.start_soon(Clock(ip_codma_top.clk_i, 10, units="ns").start())

    # Apply reset
    ip_codma_top.rst_n_i.value = 0  # Active-low reset
    ip_codma_top._log.info("Reset asserted")
    await Timer(20, units="ns")  # Hold reset for 20ns
    ip_codma_top.rst_n_i.value = 1
    ip_codma_top._log.info("Reset deasserted")

    # Wait a few clock cycles
    for _ in range(5):
        await RisingEdge(ip_codma_top.clk_i)