// Temp testbench to check verification will work

// NOTE: ACTIVE LOW RESET
`timescale 1 ns/10 ps
localparam CLK_PERIOD = 20;

`include "global_params.sv"

module temp_tb;

    logic clk_i;
    logic reset_n_i;

    top UUT (
        .clk_i(clk_i),
        .reset_n_i(reset_n_i)
    );

    always #(CLK_PERIOD/2) clk_i = ~clk_i;
    initial begin
        reset_n_i <=1;
        #CLK_PERIOD
        reset_n_i <=0;
    end

endmodule