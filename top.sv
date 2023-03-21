/*
Oliver Anderson
Univeristy of Bath
codma FYP 2023

Top level module file for the codma. This file connects the codma, read and write machine modules.
It is the ONLY module to drive the bus interface signals to avoid contentions.
It will contain the assertions to confirm the state machines do not fall into unknown states. Though
the unknown states will be defined for a "belt and braces" approach to eliminate this as a point of failure.
*/
`include "machine_pkg.sv"

//=======================================================================================
// CODMA MODULE START
//=======================================================================================
module ip_codma_top
#()(
    // clock and reset
    input 		clk_i,
    input		reset_n_i,

    // control interface
    input		    start_i,
    input		    stop_i,
    output logic	busy_o,
    input [31:0]    task_pointer_i,
    input [31:0]    status_pointer_i,

    // bus interface
    BUS_IF.master	bus_if,

    // interrupt output
    output logic	irq_o

);

//=======================================================================================
// INTERNAL SIGNALS AND MARKERS
//=======================================================================================

logic [31:0] reg_addr, reg_addr_wr;
logic [7:0]  reg_size, reg_size_wr;
logic need_read_i, need_read_o;
logic need_write_i, need_write_o;
logic [7:0] write_count_s;

logic [7:0][31:0] data_reg;
logic [7:0][31:0] write_data;
logic [7:0][31:0] crc_code;

read_pkg::read_state_t      rd_state_r;
read_pkg::read_state_t      rd_state_next_s; 
write_pkg::write_state_t    wr_state_r;      
write_pkg::write_state_t    wr_state_next_s;
dma_pkg::dma_state_t        dma_state_r;
dma_pkg::dma_state_t        dma_state_next_s;

//=======================================================================================
// CONNECT THE MODULES
//=======================================================================================

read_machine inst_rd_machine(
    .clk_i(clk_i),
    .reset_n_i(reset_n_i),
    .need_read_i(need_read_i),
    .need_read_o(need_read_o),
    .rd_state_r(rd_state_r),
    .rd_state_next_s(rd_state_next_s),
    .data_reg_o(data_reg),
    .bus_if(bus_if)
);

write_machine inst_wr_machine(
    .clk_i(clk_i),
    .reset_n_i(reset_n_i),
    .need_write_i(need_write_i),
    .need_write_o(need_write_o),
    .word_count_wr(write_count_s),
    .wr_state_r(wr_state_r),
    .wr_state_next_s(wr_state_next_s),
    .rd_state_next_s(rd_state_next_s),
    .bus_if(bus_if)
);

codma_machine inst_dma_machine(
    .clk_i(clk_i),
    .reset_n_i(reset_n_i),
    .start_i(start_i),
    .stop_i(stop_i),
    .busy_o(busy_o),
    .irq_o(irq_o),
    .task_pointer_i(task_pointer_i),
    .status_pointer_i(status_pointer_i),
    .rd_state_next_s(rd_state_next_s),
    .rd_state_r(rd_state_r),
    .wr_state_next_s(wr_state_next_s),
    .dma_state_next_s(dma_state_next_s),
    .dma_state_r(dma_state_r),
    .reg_addr(reg_addr),
    .reg_size(reg_size),
    .reg_addr_wr(reg_addr_wr),    
    .reg_size_wr(reg_size_wr),    
    .need_read_i(need_read_i),
    .need_read_o(need_read_o),
    .need_write_i(need_write_i),
    .need_write_o(need_write_o),
    .write_data(write_data),
    .data_reg(data_reg)
);

compute_crc inst_compute_crc (
    .clk_i(clk_i),
    .reset_n_i(reset_n_i),
    .data_reg(data_reg),
    .dma_state_next_s(dma_state_next_s),
    .crc_output(crc_code)
);

//=======================================================================================
//      DRIVE THE BUS. BRUM BRUM
//      .-------------------------------------------------------------.
//      '------..-------------..----------..----------..----------..--.|
//      |       \\            ||          ||          ||          ||  ||
//      |        \\           ||          ||          ||          ||  ||
//      |    ..   ||  _    _  ||    _   _ || _    _   ||    _    _||  ||
//      |    ||   || //   //  ||   //  // ||//   //   ||   //   //|| /||
//      |_.------"''----------''----------''----------''----------''--'|
//       |)|      |       |       |       |    |         |      ||==|  |
//       | |      |  _-_  |       |       |    |  .-.    |      ||==| C|
//       | |  __  |.'.-.' |   _   |   _   |    |.'.-.'.  |  __  | "__=='
//       '---------'|( )|'----------------------'|( )|'----------""
//                   '-'                          '-'
//=======================================================================================
always_comb begin
    // Standard Values
    bus_if.read         = 'd0;
    bus_if.write        = 'd0;
    bus_if.write_valid  = 'd0;
    bus_if.write_data   = 'd0;
    bus_if.size         = 'd9;
    bus_if.write_data   = {write_data[write_count_s+1],write_data[write_count_s]};

    // Wants to Read
    if (rd_state_r == read_pkg::RD_ASK) begin
        bus_if.read     = 'd1;
        bus_if.size     = reg_size;
        bus_if.addr     = reg_addr;
    end else if (rd_state_r == read_pkg::RD_GRANTED) begin
        bus_if.size     = reg_size;
        bus_if.addr     = reg_addr;
    // Wants to Write
    end else if (wr_state_r == write_pkg::WR_ASK) begin
        bus_if.write        = 'd1;
        bus_if.size         = reg_size_wr;
        bus_if.addr         = reg_addr_wr;
    end else if (wr_state_r == write_pkg::WR_GRANTED) begin
        bus_if.size         = reg_size_wr;
        bus_if.addr         = reg_addr_wr;
        bus_if.write_valid  = 'd1;
    end 
end

//=======================================================================================
// ASSERTIONS (NOT FUNCTIONNING)
//=======================================================================================
//assert property (
//    @(clk_i) (dma_state_next_s == dma_pkg::DMA_COMPUTE)
//) else $error("TEST ERROR");

endmodule
