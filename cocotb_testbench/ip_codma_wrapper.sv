// Wrapper for splitting the typedef struct packed into logic signals.
// Making interfacing with Verilator & cocotb easier as Verilator does not support proper sv interfaces (modports)

module ip_codma_wrapper #()(
    input clk_i, reset_n_i,

    // CPU interface
    input           start, stop,
    output          irq, busy,
	input [31:0]    status_pointer, task_pointer,

    // Memory interface
    output		    read, write, 
    output	[31:0]	addr,
	output	[3:0]	size,
    input 		    grant,
	input	[63:0]	read_data,
	input		    read_valid,
	output	[63:0]	write_data,
	output		    write_valid,
	input		    error
);

cpu_interface_t cpu_if;

assign cpu_if.start             = start;
assign cpu_if.stop              = stop;
assign irq                      = cpu_if.irq;
assign busy                     = cpu_if.busy;
assign cpu_if.status_pointer    = status_pointer;
assign cpu_if.task_pointer      = task_pointer;

mem_interface_t mem_if;

assign read                 = mem_if.read;
assign write                = mem_if.write;
assign addr                 = mem_if.addr;
assign size                 = mem_if.size;
assign mem_if.grant         = grant;
assign mem_if.read_data     = read_data;
assign mem_if.read_valid    = read_valid;
assign write_data           = mem_if.write_data;
assign write_valid          = mem_if.write_valid;
assign mem_if.error         = error;



ip_codma_top inst_dut(
    .clk_i      (clk_i),
    .reset_n_i  (reset_n_i),
    .cpu_if     (cpu_if),
    .bus_if     (mem_if)
);

endmodule;
