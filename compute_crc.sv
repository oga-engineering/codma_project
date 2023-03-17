// Module for the compute CRC code implementation
module compute_crc (
        input                       clk_i,
        input                       reset_n_i,
        input        [7:0][31:0]    data_reg,
        input                       dma_pkg::dma_state_t dma_state_next_s,
        output logic [7:0][31:0]    crc_output
    );

    always_ff @(posedge clk_i, reset_n_i) begin
        if(!reset_n_i)begin
            crc_output <= 'd0;
        end else begin
            if(dma_state_next_s == dma_pkg::DMA_COMPUTE)begin
                crc_output <= 'd1;
            end
        end
    end


endmodule