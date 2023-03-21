/*
Oliver Anderson
Univeristy of Bath
codma FYP 2023

This file contains the modules used for the read and write machines. 
I have attempted to keep all signals and states relative to these modules in this file
for better clarity. For hardware optimisation the two could be combined, however I am not sure
if this would allow for pipelining.
*/
`include "machine_pkg.sv"

//=======================================================================================
// READ MACHINE
//=======================================================================================
module read_machine (
        input               clk_i,
        input               reset_n_i,
        input               need_read_i,
        output logic        need_read_o,
        output logic [7:0][31:0]  data_reg_o,
        output              read_pkg::read_state_t rd_state_r,
        output              read_pkg::read_state_t rd_state_next_s,
        BUS_IF.master       bus_if
    );
    logic [7:0]  word_count_rd;
    logic [63:0] old_data;
    logic [3:0]  rd_size;

    //--------------------------------------------------
    // FINITE STATE MACHINE
    //--------------------------------------------------
    always_comb begin
        rd_state_next_s = rd_state_r;
        case(rd_state_r)
            read_pkg::RD_IDLE:
            begin
                if (need_read_i) begin
                    rd_state_next_s = read_pkg::RD_ASK;
                end
            end
            read_pkg::RD_ASK:
            begin
                if (bus_if.grant) begin
                    rd_state_next_s = read_pkg::RD_GRANTED;
                end
            end
            read_pkg::RD_GRANTED:
            begin
                // Looking for the word count to match expected words
                if (rd_size == 9 && word_count_rd == 8) begin
                    rd_state_next_s = read_pkg::RD_IDLE;
                end else if (rd_size == 8 && word_count_rd == 4) begin
                    rd_state_next_s = read_pkg::RD_IDLE;
                end else if (rd_size == 3 && word_count_rd == 2) begin
                    rd_state_next_s = read_pkg::RD_IDLE;
                end
            end
        endcase
    end
    
    //--------------------------------------------------
    // REGISTER OPERATIONS
    //--------------------------------------------------
    always_ff @(posedge clk_i, reset_n_i) begin
        if (!reset_n_i) begin
            need_read_o   <= 'd0;
            data_reg_o    <= 'd0;
            word_count_rd <= 'd0;
            old_data      <= 'd0;
            rd_size       <= 'd0;
            rd_state_r    <= read_pkg::RD_IDLE;

        //--------------------------------------------------
        // ERROR HANDLING (FROM BUS)
        //--------------------------------------------------
        end else if (bus_if.error) begin
            rd_state_r <= read_pkg::RD_IDLE;

        //--------------------------------------------------
        // NORMAL CONDITIONS
        //--------------------------------------------------
        end else begin
            rd_state_r  <= rd_state_next_s;
            if (rd_state_next_s == read_pkg::RD_IDLE) begin
                word_count_rd   <= 'd0;
                old_data        <= 'd0;
                rd_size         <= 'd0;
            end else if (rd_state_next_s == read_pkg::RD_ASK) begin
                rd_size     <= bus_if.size;
                need_read_o   <= 'd0;
            end else if (rd_state_next_s == read_pkg::RD_GRANTED) begin
                need_read_o   <= 'd0;
                if (old_data != bus_if.read_data && bus_if.read_valid) begin
                    data_reg_o[word_count_rd]    <= bus_if.read_data[31:0];
                    data_reg_o[word_count_rd+1]  <= bus_if.read_data[63:32];
                    word_count_rd <= word_count_rd + 2;
                    old_data <= bus_if.read_data;
                end
            end
        end
    end
endmodule


//=======================================================================================
// WRITE MACHINE
//=======================================================================================
module write_machine(
        input               clk_i,
        input               reset_n_i,

        input               need_write_i,
        output logic        need_write_o,

        output logic [7:0]  word_count_wr,

        output          write_pkg::write_state_t wr_state_r,
        input           read_pkg::read_state_t rd_state_next_s,
        output          write_pkg::write_state_t wr_state_next_s,

        BUS_IF.master   bus_if
    );
    
    //--------------------------------------------------
    // FINITE STATE MACHINE
    //--------------------------------------------------
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
               // write completed - look at words counted
               if (bus_if.size == 9 && word_count_wr == 8) begin
                   wr_state_next_s = write_pkg::WR_IDLE;
               end else if (bus_if.size == 8 && word_count_wr == 4)begin
                    wr_state_next_s = write_pkg::WR_IDLE;
               end else if (bus_if.size == 3 && word_count_wr == 2)begin
                    wr_state_next_s = write_pkg::WR_IDLE;
               end
           end
        endcase
    end

    //--------------------------------------------------
    // REGISTER OPERATIONS
    //--------------------------------------------------
    always_ff @(posedge clk_i, reset_n_i) begin
        if (!reset_n_i) begin
            need_write_o <= 'd0;
            wr_state_r   <= write_pkg::WR_IDLE;
        //--------------------------------------------------
        // ERROR HANDLING (FROM BUS)
        //--------------------------------------------------
        end else if (bus_if.error) begin
            wr_state_r <= write_pkg::WR_IDLE;

        //--------------------------------------------------
        // NORMAL CONDITIONS
        //--------------------------------------------------
        end else begin
            wr_state_r  <= wr_state_next_s;
            if (wr_state_next_s == write_pkg::WR_IDLE) begin
                word_count_wr       <= 'd0;
            end else if (wr_state_next_s == write_pkg::WR_ASK) begin
                need_write_o   <= 'd0;
            end else if (wr_state_r == write_pkg::WR_GRANTED) begin
                need_write_o   <= 'd0;
                word_count_wr  <= word_count_wr + 2; // used to track the data written in top level
            end
        end
    end
endmodule