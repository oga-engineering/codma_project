/*
Oliver Anderson
Univeristy of Bath
codma FYP 2023

This file contains the modules used for the read and write machines. 
I have attempted to keep all signals and states relative to these modules in this file
for better clarity. For hardware optimisation the two could be combined, however I am not sure
if this would allow for pipelining.
*/

import ip_codma_machine_states_pkg::*;

//=======================================================================================
// READ MACHINE
//=======================================================================================
module ip_codma_read_machine (
        input               clk_i,
        input               reset_n_i,
        output logic        rd_state_error,
        input               need_read_i,
        output logic        need_read_o,
        input               stop_i,
        output logic [7:0][31:0]  data_reg_o,
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

        if (stop_i) begin
            rd_state_next_s = RD_IDLE;
        end

        case(rd_state_r)
            RD_IDLE:
            begin
                if (need_read_i) begin
                    rd_state_next_s = RD_ASK;
                end
            end
            RD_ASK:
            begin
                if (bus_if.grant) begin
                    rd_state_next_s = RD_GRANTED;
                end
            end
            RD_GRANTED:
            begin
                // Looking for the word count to match expected words
                if (rd_size == 9 && word_count_rd == 6) begin
                    rd_state_next_s = RD_IDLE;
                end else if (rd_size == 8 && word_count_rd == 2) begin
                    rd_state_next_s = RD_IDLE;
                end else if (rd_size == 3 && word_count_rd == 0) begin
                    rd_state_next_s = RD_IDLE;
                end
            end
            // If in this state return to idle
            RD_UNUSED:
            begin
                rd_state_next_s = RD_IDLE;
            end
        endcase
    end
    
    //--------------------------------------------------
    // REGISTER OPERATIONS
    //--------------------------------------------------
    always_ff @(posedge clk_i, reset_n_i) begin
        if (!reset_n_i) begin
            rd_state_error <= 'd0;
            need_read_o   <= 'd0;
            data_reg_o    <= 'd0;
            word_count_rd <= 'd0;
            rd_size       <= 'd0;
            rd_state_r    <= RD_IDLE;

        //--------------------------------------------------
        // ERROR HANDLING (FROM BUS)
        //--------------------------------------------------
        end else if (bus_if.error || dma_state_r == DMA_ERROR) begin
            rd_state_r <= RD_IDLE;

        //--------------------------------------------------
        // NORMAL CONDITIONS
        //--------------------------------------------------
        end else begin
            rd_state_r  <= rd_state_next_s;
            if (rd_state_next_s == RD_IDLE) begin
                word_count_rd   <= 'd0;
                rd_size         <= 'd0;
                rd_state_error  <= 'd0;
            end else if (rd_state_next_s == RD_ASK) begin
                rd_size     <= bus_if.size;
                need_read_o   <= 'd0;
            
            end else if (rd_state_next_s == RD_GRANTED) begin
                need_read_o   <= 'd0;
                // count each valid
                if (bus_if.read_valid) begin
                    data_reg_o[word_count_rd]    <= bus_if.read_data[31:0];
                    data_reg_o[word_count_rd+1]  <= bus_if.read_data[63:32];
                    word_count_rd <= word_count_rd + 2;
                end


            end else if (rd_state_next_s == RD_UNUSED) begin
                rd_state_error <= 'd1;
            end
        end
    end
endmodule


//=======================================================================================
// WRITE MACHINE
//=======================================================================================
module ip_codma_write_machine(
        input               clk_i,
        input               reset_n_i,

        output logic        wr_state_error,

        input               need_write_i,
        output logic        need_write_o,

        input               stop_i,

        output logic [7:0]  word_count_wr,

        BUS_IF.master   bus_if
    );
    
    //--------------------------------------------------
    // FINITE STATE MACHINE
    //--------------------------------------------------
    always_comb begin
        wr_state_next_s = wr_state_r;
        if (stop_i)begin
            wr_state_next_s = WR_IDLE;
        end
        case(wr_state_r)
           WR_IDLE:
           begin
               if (need_write_i) begin
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
               // write completed - look at words counted
               if (bus_if.size == 9 && word_count_wr == 6) begin
                   wr_state_next_s = WR_IDLE;
               end else if (bus_if.size == 8 && word_count_wr == 2)begin
                    wr_state_next_s = WR_IDLE;
               end else if (bus_if.size == 3 && word_count_wr == 0)begin
                    wr_state_next_s = WR_IDLE;
               end
           end
           // Broken state return to idle
           WR_UNUSED:
           begin
                wr_state_next_s = WR_IDLE;
           end
        endcase
    end

    //--------------------------------------------------
    // REGISTER OPERATIONS
    //--------------------------------------------------
    always_ff @(posedge clk_i, reset_n_i) begin
        if (!reset_n_i) begin
            need_write_o    <= 'd0;
            wr_state_error  <= 'd0;
            wr_state_r      <= WR_IDLE;
        //--------------------------------------------------
        // ERROR HANDLING (FROM BUS)
        //--------------------------------------------------
        // Do not send to idle at dma error - must update status pointer addr
        end else if (bus_if.error) begin
            wr_state_r <= WR_IDLE;

        //--------------------------------------------------
        // NORMAL CONDITIONS
        //--------------------------------------------------
        end else begin
            wr_state_r  <= wr_state_next_s;
            if (wr_state_next_s == WR_IDLE) begin
                word_count_wr   <= 'd0;
                need_write_o    <= 'd0;
            end else if (wr_state_next_s == WR_ASK) begin
                need_write_o    <= 'd0;
            end else if (wr_state_r == WR_GRANTED) begin
                need_write_o    <= 'd0;
                word_count_wr   <= word_count_wr + 2; // used to track the data written in top level
            end else if (wr_state_next_s == WR_UNUSED) begin
                wr_state_error  <= 'd1;
            end
        end
    end
endmodule