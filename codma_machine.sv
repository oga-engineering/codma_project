module codma_machine (   
        input               clk_i,
        input               reset_n_i,    
        input               start_i,
        output logic        busy_o,
        output logic        irq_o,
        input [31:0]        task_pointer_i,
        input               read_pkg::read_state_t rd_state_next_s,
        output              read_pkg::read_state_t rd_state_r,
        input               write_pkg::write_state_t wr_state_next_s,
        output              write_pkg::write_state_t wr_state_r,
        output              dma_pkg::dma_state_t dma_state_r,
        output              dma_pkg::dma_state_t dma_state_next_s,

        output logic [31:0] reg_addr,
        output logic [7:0]  reg_size,

        output logic        need_read_i,
        input               need_read_o,
        output logic        need_write_i,
        input               need_write_o,
        output logic [7:0][31:0] write_data,
        input [7:0][31:0]   data_reg
    );
    
    // internal registers
    logic [7:0][31:0] task_dependant_data;
    logic [31:0] task_type;
    logic [31:0] destin_addr;
    logic [31:0] source_addr;
    logic [31:0] len_bytes;
    logic [31:0] task_pointer_s;
    logic        error_flag;

    always_comb begin
        dma_state_next_s    = dma_state_r;
        case(dma_state_r)
            dma_pkg::DMA_IDLE:
            begin
                if (busy_o) begin
                    dma_state_next_s = dma_pkg::DMA_PENDING;
                end
            end
            dma_pkg::DMA_PENDING:
            begin
                // once the task has been read from the pointer
                if (rd_state_next_s == read_pkg::RD_IDLE) begin
                    dma_state_next_s = dma_pkg::DMA_DATA_READ;
                end
            end

            dma_pkg::DMA_TASK_READ: // Used for link_task - 2. Otherwise skipped
            begin
                if (rd_state_next_s == read_pkg::RD_IDLE) begin
                    dma_state_next_s = dma_pkg::DMA_DATA_READ;
                end
            end 

            dma_pkg::DMA_DATA_READ: // reads the source data
            begin
                // move operation
                if (rd_state_next_s == read_pkg::RD_IDLE) begin
                    dma_state_next_s = dma_pkg::DMA_WRITING;
                end
            end

            dma_pkg::DMA_WRITING:
            begin
                // add provision for NBytes
                if (wr_state_next_s == write_pkg::WR_IDLE) begin
                    if(len_bytes != 'd0 ) begin
                        dma_state_next_s = dma_pkg::DMA_DATA_READ;
                    end else if(task_type != 'd2) begin
                        dma_state_next_s = dma_pkg::DMA_IDLE;
                    end else if (task_type == 'd2) begin
                        dma_state_next_s = dma_pkg::DMA_TASK_READ;
                    end
                end
            end
            // RESERVED FOR TASK TYPE 3 - CRC COMPUTE
            dma_pkg::DMA_COMPUTE:
            begin
                $display("DMA COMPUTE NOT YET DEFINED");
                dma_state_next_s = dma_pkg::DMA_IDLE;
            end
        endcase
    end

    always_ff @(posedge clk_i, reset_n_i) begin
        //--------------------------------------------------
        // RESET CONDITIONS
        //--------------------------------------------------
        if (!reset_n_i) begin
            rd_state_r          <= read_pkg::RD_IDLE;
            wr_state_r          <= write_pkg::WR_IDLE;
            dma_state_r         <= dma_pkg::DMA_IDLE;
            busy_o              <= 'd0;
            irq_o               <= 'd0;
            reg_addr            <= 'd0;
            task_dependant_data <= 'd0;
            reg_size            <= 'd0;
            need_read_i         <= 'd0;
            need_write_i        <= 'd0;
            source_addr         <= 'd0;
            error_flag          <= 'd0;    
        //--------------------------------------------------
        // RUNTIME OPERATIONS
        //--------------------------------------------------
        end else begin
            // MACHINE STATES
            rd_state_r  <= rd_state_next_s;
            wr_state_r  <= wr_state_next_s;
            dma_state_r <= dma_state_next_s;
            need_read_i <= need_read_o;
            need_write_i <= need_write_o;
    
            // NEW TASK CONDITIONS (DMA_PENDING)
            if (!busy_o && start_i) begin
                // SET OUTPUT FLAGS
                busy_o      <= 'd1;            
                // READ ADDRESS IN POINTER
                reg_addr    <= task_pointer_i;
                task_pointer_s <= task_pointer_i;
                reg_size    <= 'd9;
                need_read_i <= 'd1;
            end
    
            //------------------------------------------------------------------------
            // DMA REGISTERS
            //------------------------------------------------------------------------
            if (dma_state_next_s == dma_pkg::DMA_IDLE) begin
                task_type   <= 'd0;
                destin_addr <= 'd0;
                len_bytes   <= 'd0;
                
                //deassert busy_o
                if (dma_state_r == dma_pkg::DMA_COMPUTE || dma_state_r == dma_pkg::DMA_WRITING) begin
                    busy_o  <= 'd0;
                end
    
            // TASK 2 SPECIFIC STATE
            //------------------------------------------------------------------------
            end else if (dma_state_next_s == dma_pkg::DMA_TASK_READ) begin
                need_read_i     <= 'd1;
                reg_size        <= 'd9;
                reg_addr        <= task_pointer_s;
                if (dma_state_r == dma_pkg::DMA_WRITING) begin
                    task_pointer_s  <= task_pointer_s + 'd32;
                end

            // GATHERING DATA TO TRANSFER
            //------------------------------------------------------------------------
            end else if (dma_state_next_s == dma_pkg::DMA_DATA_READ) begin
                
                need_read_i <= 'd1;
                // mid write cycle
                if (dma_state_r == dma_pkg::DMA_WRITING && task_type == 'd0) begin
                    reg_addr    <= source_addr + 'd8;
                    source_addr <= source_addr + 'd8;
                    destin_addr <= destin_addr + 'd8;
                    // other values stay the same

                end else if (dma_state_r == dma_pkg::DMA_WRITING && task_type != 'd0) begin
                    reg_addr    <= source_addr + 'd32;
                    source_addr <= source_addr + 'd32;
                    destin_addr <= destin_addr + 'd32;
                    // other values stay the same
            
                // first write cycle
                end else if (dma_state_r == dma_pkg::DMA_PENDING || dma_state_r == dma_pkg::DMA_TASK_READ) begin
                    task_type   <= data_reg[0];
                    reg_addr    <= data_reg[1];
                    source_addr <= data_reg[1];
                    destin_addr <= data_reg[2];
                    len_bytes   <= data_reg[3];
                    // define burst size
                    // function of task type
                    if (data_reg[0] == 'd0) begin
                        reg_size <= 'd3;
                    end else if (data_reg[0] != 'd0) begin
                        reg_size <= 'd9;
                    end
                end

                // Error Check
                if (task_type > 'd3) begin
                    // error - unrecognised task type
                    error_flag <= 'd1;
                    dma_state_r <= dma_pkg::DMA_IDLE;
                end
                
            //------------------------------------------------------------------------
            end else if (dma_state_next_s == dma_pkg::DMA_WRITING) begin
                need_write_i <= 'd1;
                write_data   <= data_reg;
                reg_addr     <= destin_addr;
                // reg_size stays the same
                if (wr_state_next_s == write_pkg::WR_IDLE) begin
                    if (reg_size == 'd3) begin
                        len_bytes <= len_bytes - 'd8;
                    end else if (reg_size == 'd8) begin
                        len_bytes <= len_bytes - 'd16;
                    end else if (reg_size == 'd9) begin
                        len_bytes <= len_bytes - 'd32;
                    end
                end
            //------------------------------------------------------------------------
            end else if (dma_state_next_s == dma_pkg::DMA_COMPUTE) begin
                //$display("NO REGISTER OPERATIONS DEFINED FOR THIS TASK TYPE");
                //compute_crc inst_compute_crc (
                //    .clk_i(clk_i),
                //    .reset_n_i(reset_n_i),
                //    .data_reg(data_reg),
                //    .crc_output(crc_code)
                //);
            end
        end
    end
endmodule