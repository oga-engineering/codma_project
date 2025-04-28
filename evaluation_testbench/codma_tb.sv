/*
Oliver Anderson
Univeristy of Bath
codma FYP 2023

Proof of concept testbench to simulate the codma and find initial flaws in the logic. 
*/


module codma_tb ();

import ip_codma_states_pkg::*;
import tb_tasks_pkg::* ;

//=======================================================================================
// Local Signal Definition
//=======================================================================================
logic USE_CODMA;
assign USE_CODMA = 1;

logic DEV_CRC;
assign DEV_CRC = 0;

logic	clk, reset_n;
logic	start_s, stop_s, busy_s;
logic	[31:0]	task_pointer, status_pointer;
logic	irq_s;
BUS_IF	bus_if();

event test_done;
event check_done;

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
	status_pointer = 'd0;
	clk 	= 0;
	reset_n	= 1;
	#1
	reset_n	= 0;
	stop_s = '0;
	#30
	reset_n	= 1;
	#7000
	$display("Test Hanging");
	$stop;
end

//=======================================================================================
// Module Instantiation
//=======================================================================================

//--------------------------------------------------
// CoDMA Instantiation
//--------------------------------------------------

ip_codma_top inst_codma (
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

logic [7:0][31:0] data_reg;
logic [7:0][31:0] crc_output;
logic crc_flag_s;
assign data_reg = 'b1;
assign crc_output = 'd0;

ip_codma_crc inst_crc (
		.clk_i(clk),
		.reset_n_i(reset_n),
		.data_reg(data_reg),
		.crc_complete_flag(crc_flag_s),
		.crc_output(crc_output)
	);

//--------------------------------------------------
// Memory Instantiation
//--------------------------------------------------

ip_mem_pipelined #(
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
logic [31:0] task_type;
logic [31:0] len_bytes;
logic [31:0] source_addr_o;
logic [31:0] dest_addr_o;
logic [31:0] source_addr_l;
logic [31:0] dest_addr_l;
logic [31:0] task_type_l;
logic [31:0] len_bytes_l;
logic [31:0][7:0][7:0] int_mem;

initial 
begin

//--------------------------------------------------
// Set Default Values
//--------------------------------------------------
	dma_state_t        dma_state_r;
	dma_state_t        dma_state_next_s;

	#40	// wait for reset to finish

//--------------------------------------------------
// Setup ip_mem
//--------------------------------------------------

	// Fill Memory with random values
	@(negedge clk);
	for (int i=0; i<inst_mem.MEM_DEPTH; i++) begin
		inst_mem.mem_array[i] = {$random(),$random()};
	end
	

//--------------------------------------------------
// CRC DEV
//--------------------------------------------------

if (DEV_CRC) begin
	$display("CRC under dev");
	wait (inst_crc.crc_complete_flag == 'b1);
		$display("some code %d",crc_output);
		#60
		$stop;
end

//--------------------------------------------------
// Co-DMA stimulus
//--------------------------------------------------
if (USE_CODMA) begin
	for (int i=0; i<5; i++) begin
		fork
			//--------------------------------------------------
			// DRIVE THREAD
			//--------------------------------------------------
			begin
				//#1 8 Bytes chunks
				task_type = 'd0;
				len_bytes = ($urandom_range(1,4)*8);
				task_pointer = ($urandom_range(8,(inst_mem.MEM_DEPTH-4))*inst_mem.MEM_WIDTH);
				setup_data(
				inst_mem.mem_array,
				inst_mem.mem_array,
				task_pointer,
				task_type,
				len_bytes,
				source_addr_o,
				dest_addr_o,
				source_addr_l,
				dest_addr_l,
				task_type_l,
				len_bytes_l,
				int_mem
			);
			start_s = '1;
			#50
			start_s = '0;
			wait(inst_codma.busy_o == 'd0);
			-> test_done;

				//#2 32 bytes chunks
				@(check_done);
				task_type = 'd1;
				len_bytes = ($urandom_range(1,3)*32);
				task_pointer = ($urandom_range(8,(inst_mem.MEM_DEPTH-4))*inst_mem.MEM_WIDTH);
				setup_data(
				inst_mem.mem_array,
				inst_mem.mem_array,
				task_pointer,
				task_type,
				len_bytes,
				source_addr_o,
				dest_addr_o,
				source_addr_l,
				dest_addr_l,
				task_type_l,
				len_bytes_l,
				int_mem
			);
			start_s = '1;
			#50
			start_s = '0;
			wait(inst_codma.busy_o == 'd0);
			-> test_done;

				//#3 32 bytes chunks ; Move Link
				@(check_done);
				task_type = 'd2;
				len_bytes = ($urandom_range(1,2)*'d32);
				task_pointer = ($urandom_range(8,(inst_mem.MEM_DEPTH-4))*inst_mem.MEM_WIDTH);
				setup_data(
				inst_mem.mem_array,
				inst_mem.mem_array,
				task_pointer,
				task_type,
				len_bytes,
				source_addr_o,
				dest_addr_o,
				source_addr_l,
				dest_addr_l,
				task_type_l,
				len_bytes_l,
				int_mem
			);
			start_s = '1;
			#50
			start_s = '0;
			wait(inst_codma.busy_o == 'd0);
			-> test_done;
			
			//#4 Error Task
			#50
			task_type = 'hf;
			task_pointer = (inst_mem.MEM_DEPTH*inst_mem.MEM_WIDTH);
			start_s = '1;
			#50
			start_s = '0;
			wait(inst_codma.busy_o == 'd0);
			-> test_done;
			
			
			//#5 Task Type 3
			@(check_done);
			task_type = 'd3;
			len_bytes = ($urandom_range(1,2)*'d32);
			task_pointer = ($urandom_range(8,(inst_mem.MEM_DEPTH-4))*inst_mem.MEM_WIDTH);
			setup_data(
				inst_mem.mem_array,
				inst_mem.mem_array,
				task_pointer,
				task_type,
				len_bytes,
				source_addr_o,
				dest_addr_o,
				source_addr_l,
				dest_addr_l,
				task_type_l,
				len_bytes_l,
				int_mem
			);
			start_s = '1;
			#50
			start_s = '0;
			wait(inst_codma.busy_o == 'd0);


			end

			//--------------------------------------------------
			// VERIFICATION THREAD
			//--------------------------------------------------
			begin
				// Test #1
				@(test_done)
				check_data(
				inst_mem.mem_array,
					status_pointer,
					source_addr_o,
					dest_addr_o,
					source_addr_l,
					dest_addr_l,
					task_type,
					len_bytes,
					task_type_l,
					len_bytes_l,
					int_mem
				);
				-> check_done;

				// Test #2
				@(test_done)
				check_data(
				inst_mem.mem_array,
					status_pointer,
					source_addr_o,
					dest_addr_o,
					source_addr_l,
					dest_addr_l,
					task_type,
					len_bytes,
					task_type_l,
					len_bytes_l,
					int_mem
				);
				-> check_done;

				// Test #3
				@(test_done)
				check_data(
				inst_mem.mem_array,
					status_pointer,
					source_addr_o,
					dest_addr_o,
					source_addr_l,
					dest_addr_l,
					task_type,
					len_bytes,
					task_type_l,
					len_bytes_l,
					int_mem
				);
				-> check_done;

				// Test #4 - pointer addr does not exist
				@(test_done)
					#10
					$display("//-------------------------------------------------------------------------------------------------------",task_type);
	        		$display("Begin Check: task type %h",task_type);
					// Check the status output
					if (inst_mem.mem_array[status_pointer] == 'd1) begin
						$display("The status correctly reflected this error at the status address %d",(status_pointer/8));
					end else begin
						$display("The status did NOT reflect this error at the status address %d",(status_pointer/8));
					end
				-> check_done;

			end
		join
		#20
		$display("TESTS SEQUENCE %d PASS!",i);

		// Testing the stop signal
		start_s = '1;
		#50
		start_s = '0;
		#20
		stop_s = '1;
		#10
		stop_s = '0;
		#10
		$display("Stop signal test complete %d",i);

	end
	$stop;
end
end

endmodule
