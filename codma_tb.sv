module codma_tb ();

//=======================================================================================
// Local Signal Definition
//=======================================================================================
logic EXAMPLE_PRESET;
assign EXAMPLE_PRESET = 1;

logic USE_CODMA;
assign USE_CODMA = 1;

logic	clk, reset_n;
logic	start_s, stop_s, busy_s;
logic	[31:0]	task_pointer, status_pointer;
logic	irq_s;
BUS_IF	bus_if();

//=======================================================================================
// Clock and Reset Initialization
//=======================================================================================

//--------------------------------------------------
// Clocking Process
//--------------------------------------------------

always #2 clk = ~clk;

//--------------------------------------------------
// Reset Process
//--------------------------------------------------

initial begin
	clk 	= 0;
	reset_n	= 1;
	#1
	reset_n	= 0;
	#30
	reset_n	= 1;
	#1000
	$display("Simulation passed.");
	$stop;
end

//=======================================================================================
// Module Instantiation
//=======================================================================================

//--------------------------------------------------
// CoDMA Instantiation
//--------------------------------------------------

ip_codma inst_codma (
	// clock and reset
	.clk_i			(clk),
	.reset_n_i		(reset_n),
	// control interface
	.start_i		(start_s),
	.stop_i			(stop_s),
	.busy_o			(busy_s),
	.task_pointer_i		(task_pointer),
	.status_pointer_i	(status_pointer),
	// bus interface
	.bus_if			(bus_if.master),
	// interrupt output
	.irq_o			(irq_s)
);

//--------------------------------------------------
// Memory Instantiation
//--------------------------------------------------

ip_mem #(
	.MEM_DEPTH	(32),
	.MEM_WIDTH	(8)
) inst_mem (
	// clock and reset
	.clk_i		(clk),
	.reset_n_i	(reset_n),
	// bus interface
	.bus_if		(bus_if.slave)
);

//=======================================================================================
// TB Example Stimulus 
//=======================================================================================

initial 
begin

//--------------------------------------------------
// Set Default Values
//--------------------------------------------------

	bus_if.read		= '0;
	bus_if.write		= '0;
	bus_if.addr		= '0;
	bus_if.size		=  9;
	bus_if.write_data	= '0;
	bus_if.write_valid	= '0;

	#40	// wait for reset to finish

//--------------------------------------------------
// Setup ip_mem
//--------------------------------------------------

	/* can be used to put random values in the whole memory
	@(negedge clk);
	for (int i=0; i<inst_mem.MEM_DEPTH; i++) begin
		inst_mem.mem_array[i] = {$random(),$random()};
	end
	*/

	@(negedge clk);
	inst_mem.mem_array[0] = 64'h00000000ffffffff;
	inst_mem.mem_array[1] = 64'hffffffff00000000;

//--------------------------------------------------
// Co-DMA stimulus
// TASK  TYPE 0 - BASIC MOVE
//--------------------------------------------------

if (USE_CODMA) begin
// Send info to addr (without bus_if)
inst_mem.mem_array[3] = 64'hf0f0f0f000000000;
inst_mem.mem_array[2] = 64'h1011011100000000;
task_pointer = 'd1;
start_s = '1;

end



if (EXAMPLE_PRESET) begin
	//--------------------------------------------------
	// 1 Double Word Write Error Example 
	//--------------------------------------------------

		#50								// spaceing to seperate examples

		@(negedge clk);
		bus_if.write	= '1;						// send write request on bus_if
		bus_if.addr	= (inst_mem.MEM_DEPTH*inst_mem.MEM_WIDTH);	// address is the size of memory which does not exist
		bus_if.size	= 3;						// size is 3 (1 double word)

		@(negedge (bus_if.grant));
		bus_if.write	= '0;						// when grant detected, de-assert write request

		// ip_mem will error 1 cycle after grant in data phase 

	//--------------------------------------------------
	// 2 Double Word Read Burst Example 
	//--------------------------------------------------

		#50								// spaceing to seperate examples

		@(negedge clk);
		bus_if.read	= '1;						// send read request on bus_if
		bus_if.addr	= 0;						// address is 0 (1st double word of memory)
		bus_if.size	= 8;						// size is 8 (2 double word burst)

		@(negedge (bus_if.grant));
		bus_if.read	= '0;						// when grant detected, de-assert read request

		// ip_mem will provide a read_valid along with the data in the first and second double words of memory (address 0 and 8). Check this in the waveforms.

	//--------------------------------------------------
	// 4 Double Word Write Burst Example 
	//--------------------------------------------------

		#50								// spaceing to seperate examples

		@(negedge clk);
		bus_if.write	= '1;						// send write request on bus_if
		bus_if.addr	= 32;						// address is 32 (5th double word of memory)
		bus_if.size	= 9;						// size is 9 (4 double word burst)

		@(negedge (bus_if.grant));
		bus_if.write	= '0;						// when grant detected, de-assert write request

		@(negedge clk);
		bus_if.write_valid	= '1;					// write data is valid
		bus_if.write_data	= 64'h000000000000ffff;			// ip_mem will take this data and put it in 5th double word of memory

		@(negedge clk);
		bus_if.write_valid	= '0;					// write data is not valid, ip_mem will ignore write_data on this cycle

		@(negedge clk);
		bus_if.write_valid	= '1;					// write data is valid
		bus_if.write_data	= 64'h00000000ffffffff;			// ip_mem will take this data and put it in 6th double word of memory

		@(negedge clk);
		bus_if.write_valid	= '0;					// write data is not valid, ip_mem will ignore write_data on this cycle

		@(negedge clk);
		bus_if.write_valid	= '1;					// write data is valid
		bus_if.write_data	= 64'h0000ffffffffffff;			// ip_mem will take this data and put it in 7th double word of memory

		@(negedge clk);
		bus_if.write_valid	= '0;					// write data is not valid, ip_mem will ignore write_data on this cycle

		@(negedge clk);
		bus_if.write_valid	= '1;					// write data is valid
		bus_if.write_data	= 64'hffffffffffffffff;			// ip_mem will take this data and put it in 8th double word of memory

		@(negedge clk);
		bus_if.write_valid	= '0;					// write data is not valid, ip_mem will ignore write_data on this cycle

		// check the  memory in waveforms to see if this data has correctly written to it
	end
end
//=======================================================================================
// TB Checker Module Instantiation
//=======================================================================================

// TB checking
ip_checker inst_checker (
	.clk_i			(clk),
	.reset_n_i		(reset_n),
	.bus_if			(bus_if.monitor),
	.irq_i			(irq_s),
	.start_i		(start_s),
	.stop_i			(stop_s),
	.busy_i			(busy_s),
	.task_pointer_i		(task_pointer),
	.status_pointer_i	(status_pointer)
);

endmodule
