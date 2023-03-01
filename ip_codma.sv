//`include "codma_tasks.sv"
module ip_codma
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
logic need_read;
logic need_write;

logic [7:0][31:0] data_reg;
logic [7:0] word_count_rd;
logic [7:0] word_count_wr;
logic [63:0] old_data;

logic [31:0] task_type;
logic [31:0] source_addr;
logic [31:0] destin_addr;
logic [31:0] len_bytes;

//--------------------------------------------------
// STATE MACHINES (BUS_IF MASTER)
//--------------------------------------------------

// READ MACHINE
typedef enum logic [1:0]
{
  RD_IDLE	    = 2'b00,				 
  RD_ASK 	    = 2'b01,
  RD_GRANTED	= 2'b10
}
read_state_t;
read_state_t    rd_state_r;
read_state_t    rd_state_next_s;

// WRITE MACHINE
typedef enum logic [1:0]
{
  WR_IDLE	    = 2'b00,				 
  WR_ASK 	    = 2'b01,
  WR_GRANTED	= 2'b10
}
write_state_t;
write_state_t    wr_state_r;
write_state_t    wr_state_next_s;

//--------------------------------------------------
// DMA OPERATION MACHINE
//--------------------------------------------------
typedef enum logic [2:0]
{
  DMA_IDLE	    = 3'b000,				 
  DMA_PENDING   = 3'b001,
  DMA_SETUP	    = 3'b010,
  DMA_READING   = 3'b100,
  //DMA_COMPUTE   = 3'b110,
  DMA_WRITING   = 3'b101
}
dma_state_t;
dma_state_t dma_state_r;
dma_state_t dma_state_next_s;

//--------------------------------------------------
// STATE MACHINE LOGIC
//--------------------------------------------------
always_comb begin
    //--------------------------------------------------
    // DEFAULTS
    //--------------------------------------------------
    rd_state_next_s     = rd_state_r;
    wr_state_next_s     = wr_state_r;
    dma_state_next_s    = dma_state_r;

    //--------------------------------------------------
    // READ PHASE STATE MACHINE
    //--------------------------------------------------
    case(rd_state_r)
        RD_IDLE:
        begin
            // DEFAULT VALUES
            if (need_read) begin
                rd_state_next_s = RD_ASK;
            end
        end
        // A READ HAS BEEN REQUESTED
        RD_ASK:
        begin
            if (bus_if.grant) begin
                rd_state_next_s = RD_GRANTED;
            end
        end
        // THE READ IS GRANTED
        RD_GRANTED:
        begin
            // CONDITIONS TO LEAVE THE READING STATE
            if (bus_if.size == 9 && word_count_rd == 8) begin
                rd_state_next_s = RD_IDLE;
            end
            if (bus_if.error) begin
                rd_state_next_s = RD_IDLE;
            end
        end
    endcase

    //--------------------------------------------------
    // WRITE PHASE STATE MACHINE
    //--------------------------------------------------
    case(wr_state_r)
        WR_IDLE:
        begin
            if (need_write) begin
                wr_state_next_s = WR_ASK;
            end
        end
        WR_ASK:
        begin
            if (bus_if.grant) begin
                wr_state_next_s = WR_GRANTED;
            end
        end
        WR_GRANTED:
        begin
            // CONDITIONS TO LEAVE THE WRITING STATE
            if (bus_if.size == 9 && word_count_wr == 8) begin
                wr_state_next_s = WR_IDLE;
            end
            if (bus_if.error) begin
                wr_state_next_s = WR_IDLE;
            end
        end
    endcase

    //--------------------------------------------------
    // TASK OPERATION
    //--------------------------------------------------
    case(dma_state_r)
        DMA_IDLE:
        begin
            if (busy_o) begin
                dma_state_next_s = DMA_PENDING;
            end
        end
        DMA_PENDING:
        begin
            // once the task has been read from the pointer
            if (rd_state_next_s == RD_IDLE) begin
                dma_state_next_s = DMA_SETUP;
            end
        end
        DMA_SETUP:
        begin
            // move operation
            if(task_type == 'd1) begin
                dma_state_next_s = DMA_READING;
            end
        end
        DMA_READING:
        begin
            // MOVE TYPE OPERATION
            if(task_type == 'd1) begin
                // READ OF SOURCE ADDRESS COMPLETE
                // ONCE READ MACHINE RETURNS TO IDLE
                if (rd_state_next_s == RD_IDLE) begin
                    dma_state_next_s = DMA_WRITING;
                end
            end
        end
        DMA_WRITING:
        begin
            if(wr_state_next_s == WR_IDLE) begin
                dma_state_next_s = DMA_IDLE;
            end
        end
        // RESERVED FOR TASK TYPE 2
        //DMA_COMPUTE:
        //begin

        //end

    endcase

end

// ====================================================================================

//--------------------------------------------------
// CLOCKED REGISTERS
//--------------------------------------------------

always_ff @(posedge clk_i, reset_n_i) begin
    //--------------------------------------------------
    // RESET CONDITIONS
    //--------------------------------------------------
    if (!reset_n_i) begin
        rd_state_r  <= RD_IDLE;
        wr_state_r  <= WR_IDLE;
        dma_state_r <= DMA_IDLE;
        busy_o      <= 'd0;
        irq_o       <= 'd0;
        reg_addr    <= 'd0;
        data_reg    <= 'd0;
        reg_size    <= 'd0;
        need_read   <= 'd0;
        need_write  <= 'd0;

    //--------------------------------------------------
    // RUNTIME OPERATIONS
    //--------------------------------------------------
    end else begin
        // DEFAULTS
        rd_state_r  <= rd_state_next_s;
        wr_state_r  <= wr_state_next_s;
        dma_state_r <= dma_state_next_s;

        // NEW TASK CONDITIONS
        if (!busy_o && start_i) begin
            // SET OUTPUT FLAGS
            busy_o      <= 'd1;            
            // READ ADDRESS IN POINTER
            reg_addr    <= task_pointer_i;
            reg_size    <= 'd9;
            data_reg    <= 'd0;
            need_read   <= 'd1;
        end

        //--------------------------------------------------
        // DMA REGISTERS
        //--------------------------------------------------
        if (dma_state_next_s == DMA_IDLE) begin
            task_type   <= 'd0;
            source_addr <= 'd0;
            destin_addr <= 'd0;
            len_bytes   <= 'd0;
        end else if (dma_state_next_s == DMA_SETUP) begin
            task_type   <= data_reg[0];
            source_addr <= data_reg[1];
            destin_addr <= data_reg[2];
            len_bytes   <= data_reg[3];
        end else if (dma_state_next_s == DMA_READING) begin
            need_read   <= 'd1;
            reg_size    <= len_bytes;
            reg_addr    <= source_addr;
        end else if (dma_state_next_s == DMA_WRITING) begin
            need_write  <= 'd1;
            reg_addr    <= destin_addr;
            reg_size    <= len_bytes;
        end

        //--------------------------------------------------
        // READ PHASE REGISTER
        //--------------------------------------------------
        if (rd_state_next_s == RD_IDLE) begin
            busy_o          <= 'd0;
            word_count_rd   <= 'd0;
            old_data        <= 'd0;
        end else if (rd_state_next_s == RD_ASK) begin
            bus_if.read <= 'd1;
            bus_if.size <= reg_size;
            bus_if.addr <= reg_addr;
            need_read   <= 'd0;
        end else if (rd_state_next_s == RD_GRANTED) begin
            bus_if.read <= 'd0;
            need_read   <= 'd0;
            if (old_data != bus_if.read_data && bus_if.read_valid) begin
                data_reg[word_count_rd]    <= bus_if.read_data[31:0];
                data_reg[word_count_rd+1]  <= bus_if.read_data[63:32];
                word_count_rd <= word_count_rd + 2;
                old_data <= bus_if.read_data;
            end
        end

        //--------------------------------------------------
        // WRITE PHASE REGISTER
        //--------------------------------------------------
        if (wr_state_next_s == WR_IDLE) begin
            word_count_wr       <= 'd0;
            bus_if.write_valid  <= 'd0;
            bus_if.write_data   <= 'd0;
        end else if (wr_state_next_s == WR_ASK) begin
            bus_if.write <= 'd1;
            bus_if.size <= reg_size;
            bus_if.addr <= reg_addr;
            need_write   <= 'd0;
        end else if (wr_state_next_s == WR_GRANTED) begin
            need_write   <= 'd0;
            bus_if.write        <= 'd0;
            bus_if.write_valid  <= 'd1;
            bus_if.write_data   <= {data_reg[word_count_wr+1],data_reg[word_count_wr]};  
            word_count_wr       <= word_count_wr + 2;
        end
    end
        
    
end


endmodule
