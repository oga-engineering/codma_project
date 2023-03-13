// STATE MACHINES FOR THE CODMA
`include "machine_pkg.sv"

module read_machine (
        input               clk_i,
        input               reset_n_i,
        input  [31:0]       reg_addr,
        input  [7:0]        reg_size,
        input               need_read_i,
        output              need_read_o,
        output [7:0][31:0]  data_reg_o,
        input               read_pkg::read_state_t rd_state_r,
        output              read_pkg::read_state_t rd_state_next_s,
        BUS_IF.master       bus_if
    );
    logic [7:0] word_count_rd;
    logic [63:0] old_data;
    logic need_read;
    logic [7:0][31:0] data_reg;    
    assign need_read_o = need_read; 
    assign data_reg_o  = data_reg; 

    always_comb begin
        rd_state_next_s = rd_state_r;
        case(rd_state_r)
            read_pkg::RD_IDLE:
            begin
                // DEFAULT VALUES
                if (need_read_i) begin
                    rd_state_next_s = read_pkg::RD_ASK;
                end
            end
            // A READ HAS BEEN REQUESTED
            read_pkg::RD_ASK:
            begin
                if (bus_if.grant) begin
                    rd_state_next_s = read_pkg::RD_GRANTED;
                end
            end
            // THE READ IS GRANTED
            read_pkg::RD_GRANTED:
            begin
                // CONDITIONS TO LEAVE THE READING STATE
                if (bus_if.size == 9 && word_count_rd == 8) begin
                    rd_state_next_s = read_pkg::RD_IDLE;
                end else if (bus_if.size == 8 && word_count_rd == 4) begin
                    rd_state_next_s = read_pkg::RD_IDLE;
                end else if (bus_if.size == 3 && word_count_rd == 2) begin
                    rd_state_next_s = read_pkg::RD_IDLE;
                end
                if (bus_if.error) begin
                    rd_state_next_s = read_pkg::RD_IDLE;
                end
            end
        endcase
    end

    always_ff @(posedge clk_i, reset_n_i) begin
        if (!reset_n_i) begin
            need_read   <= 'd0;
            data_reg    <= 'd0;
        end else begin
            if (rd_state_next_s == read_pkg::RD_IDLE) begin
                word_count_rd   <= 'd0;
                old_data        <= 'd0;
            end else if (rd_state_next_s == read_pkg::RD_ASK) begin
                bus_if.read <= 'd1;
                bus_if.size <= reg_size;
                bus_if.addr <= reg_addr;
                need_read   <= 'd0;
            end else if (rd_state_next_s == read_pkg::RD_GRANTED) begin
                bus_if.read <= 'd0;
                need_read   <= 'd0;
                if (old_data != bus_if.read_data && bus_if.read_valid) begin
                    data_reg[word_count_rd]    <= bus_if.read_data[31:0];
                    data_reg[word_count_rd+1]  <= bus_if.read_data[63:32];
                    word_count_rd <= word_count_rd + 2;
                    old_data <= bus_if.read_data;
                end
            end
        end
    end
endmodule

module write_machine(
        input               clk_i,
        input               reset_n_i,

        input               need_write_i,
        output              need_write_o,

        input  [31:0]       reg_addr,
        input  [7:0]        reg_size,

        input [7:0][31:0]   data_reg,

        input           write_pkg::write_state_t wr_state_r,
        output          write_pkg::write_state_t wr_state_next_s,

        BUS_IF.master   bus_if
    );
    logic [7:0]    word_count_wr;
    logic          need_write;

    assign need_write_o = need_write;

    always_comb begin
        wr_state_next_s = wr_state_r;
        case(wr_state_r)
           write_pkg::WR_IDLE:
           begin
               if (need_write_i) begin
                   wr_state_next_s = write_pkg::WR_ASK;
               end
           end
           write_pkg::WR_ASK:
           begin
               if (bus_if.grant) begin
                   wr_state_next_s = write_pkg::WR_GRANTED;
               end
           end
           write_pkg::WR_GRANTED:
           begin
               // CONDITIONS TO LEAVE THE WRITING STATE
               if (bus_if.size == 9 && word_count_wr == 8) begin
                   wr_state_next_s = write_pkg::WR_IDLE;
               end else if (bus_if.size == 8 && word_count_wr == 4)begin
                    wr_state_next_s = write_pkg::WR_IDLE;
               end else if (bus_if.size == 3 && word_count_wr == 2)begin
                    wr_state_next_s = write_pkg::WR_IDLE;
               end
               if (bus_if.error) begin
                   wr_state_next_s = write_pkg::WR_IDLE;
               end
           end
        endcase
    end

    always_ff @(posedge clk_i, reset_n_i) begin
        if (!reset_n_i) begin
            need_write <= 'd0;
        end else begin
            if (wr_state_next_s == write_pkg::WR_IDLE) begin
                word_count_wr       <= 'd0;
                bus_if.write_valid  <= 'd0;
                bus_if.write_data   <= 'd0;
            end else if (wr_state_next_s == write_pkg::WR_ASK) begin
                bus_if.write <= 'd1;
                bus_if.size <= reg_size;
                bus_if.addr <= reg_addr;
                need_write   <= 'd0;
            end else if (wr_state_next_s == write_pkg::WR_GRANTED) begin
                need_write   <= 'd0;
                bus_if.write        <= 'd0;
                bus_if.write_valid  <= 'd1;
                bus_if.write_data   <= {data_reg[word_count_wr+1],data_reg[word_count_wr]};  
                word_count_wr       <= word_count_wr + 2;
            end
        end

    end
endmodule