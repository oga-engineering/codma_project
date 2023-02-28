/*
start date: 07/02/2023
Code by Oliver Anderson
University of Bath final year design project in colaboration with Infineon (Bristol)

Notes:
- All DFT considerations are left to the CPU design team
- The memory addressing scheme is little endian
- Ideally NO combinatorial paths from inputs to output. They should be registered instead. Exceptions are tolerated
- bus_if protocol TBC
- 
*/
`include "move_func.sv"
`include "bus_interface.sv"
`include "global_params.sv"

// This will be the main module for the CoDMA
module top #(
   
)
(
    input wire          clk_i,       // 500Mhz clk
    input wire          reset_n_i,   // Asynchronous Reset
    input wire          start_i,
    output reg          busy_o,
    output reg          irq,         // Interupt Signal

    input logic [31:0]  status_pointer_i, // should this not be an output ?
    input logic [31:0]  task_pointer_i              
);




// Connect the nets to the interface
bus_if #(
    .DATA_SIZE  (DATA_SIZE),
    .ADDR_SIZE  (ADDR_SIZE)
) _bus_if(
    .read_request(net_read_request),
    .write_request(net_write_request),
    .addr(net_addr),
    .size(net_size),
    .grant(net_grant),
    .read_data(net_read_data),
    .read_valid(net_read_valid),
    .write_data(net_write_data),
    .write_valid(net_write_valid),
    .error(net_error)
);

// Define the registers that can be used for driving nets
logic                 reg_read_request;
logic                 reg_write_request;
logic [ADDR_SIZE-1:0] reg_addr;
logic [3:0]           reg_size;
logic                 reg_grant;
logic [DATA_SIZE-1:0] reg_read_data;
logic                 reg_read_valid;
logic [DATA_SIZE-1:0] reg_write_data;
logic                 reg_write_valid;
logic                 reg_error;

logic                 need_read;

always_ff @(clk_i, reset_n_i ) begin
    if (!reset_n_i) begin
        busy_o              <= 'd0;
        irq                 <= 'd0;
        need_read           <= 'd0;

        reg_read_request    <= 'd0;
        reg_write_request   <= 'd0;
        reg_addr            <= 'd0;
        reg_size            <= 'd0;
        reg_grant           <= 'd0;
        reg_read_data       <= 'd0;
        reg_read_valid      <= 'd0;
        reg_write_data      <= 'd0;
        reg_write_valid     <= 'd0;
        reg_error           <= 'd0;
    end else begin
        //Determine sample
        if (!busy_o && start_i) begin
            //Sample task pointer
            reg_addr <= task_pointer_i;
            need_read <= 'd1;
        
        // execute a read request
        end else if (need_read) begin
            reg_read_request <= 'd1;

            need_read <= 'd0;
        end

        // READ TASK POINTER
        
        // Determine if this task method setup is correct
        move_0(task_pointer_i);

    end
end

assign net_read_request     = reg_read_request;
assign net_write_request    = reg_write_request;
assign net_addr             = reg_addr;
assign net_size             = reg_size;
assign net_grant            = reg_grant;
assign net_read_data        = reg_read_data;
assign net_read_valid       = reg_read_valid;
assign net_write_data       = reg_write_data;
assign net_write_valid      = reg_write_valid;
assign net_error            = reg_error;


endmodule