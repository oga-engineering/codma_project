`include "machine_pkg.sv"

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

//--------------------------------------------------
// INTERNAL SIGNALS AND MARKERS
//--------------------------------------------------

logic [31:0] reg_addr;
logic [7:0]  reg_size;
logic need_read_i, need_read_o;
logic need_write_i, need_write_o;

logic [7:0][31:0] data_reg;
logic [7:0][31:0] write_data;
logic [7:0][31:0] crc_code;

logic [31:0] len_bytes;

//--------------------------------------------------
// STATE MACHINES
//--------------------------------------------------
read_pkg::read_state_t      rd_state_r;
read_pkg::read_state_t      rd_state_next_s; 
write_pkg::write_state_t    wr_state_r;      
write_pkg::write_state_t    wr_state_next_s;
dma_pkg::dma_state_t        dma_state_r;
dma_pkg::dma_state_t        dma_state_next_s;

read_machine inst_rd_machine(
    .clk_i(clk_i),
    .reset_n_i(reset_n_i),
    .reg_addr(reg_addr),
    .reg_size(reg_size),
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
    .reg_addr(reg_addr),
    .reg_size(reg_size),
    .need_write_i(need_write_i),
    .need_write_o(need_write_o),
    .data_reg(write_data),
    .wr_state_r(wr_state_r),
    .wr_state_next_s(wr_state_next_s),
    .bus_if(bus_if)
);

codma_machine inst_dma_machine(
    .clk_i(clk_i),
    .reset_n_i(reset_n_i),
    .start_i(start_i),
    .busy_o(busy_o),
    .irq_o(irq_o),
    .task_pointer_i(task_pointer_i),
    .rd_state_next_s(rd_state_next_s),
    .rd_state_r(rd_state_r),
    .wr_state_next_s(wr_state_next_s),
    .wr_state_r(wr_state_r),    
    .dma_state_next_s(dma_state_next_s),
    .dma_state_r(dma_state_r),
    .reg_addr(reg_addr),
    .reg_size(reg_size),
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

// ASSERTIONS (NOT FUNCTIONNING)
assert property (
    @(clk_i) (dma_state_next_s == dma_pkg::DMA_COMPUTE)
) else $error("TEST ERROR");

endmodule
