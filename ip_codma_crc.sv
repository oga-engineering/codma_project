// Module for the compute CRC code implementation
import ip_codma_machine_states_pkg::*;
module ip_codma_crc (
        input                       clk_i,
        input                       reset_n_i,
        input        [7:0][31:0]    data_reg,
        output logic                crc_complete_flag,
        output logic [7:0][31:0]    crc_output
    );

    always_ff @(posedge clk_i, reset_n_i) begin
        if(!reset_n_i)begin
            crc_output          <= 'd0;
            crc_complete_flag   <= 'd0;
        end else begin
            if(dma_state_next_s == DMA_CRC)begin
                crc_output          <= data_reg;
                crc_complete_flag   <= 'd1;
            end else begin
                crc_complete_flag   <= 'd0;
            end
        end
    end


endmodule