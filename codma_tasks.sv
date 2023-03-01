/*
This will be used for the read and write tasks to improve the code...
eventually
*/

task read_bus(
    input               clk_i,
    input [31:0]        reg_addr,
    input [3:0]         size,
    output [7:0][31:0]  data_reg,
    output              read_complete
);

logic [7:0] word_count;
logic [63:0] old_data;

//always_ff @(posedge clk_i) begin
//    // pre-read conditions
//    if (!bus_if.grant) begin
//        bus_if.addr     <= reg_addr;
//        bus_if.read     <= 'd1;
//        read_complete   <= 'd0;
//        read_data       <= 'd0;
//    end else begin
//        bus_if.read <= 'd0;
//    end
//
//    // new data received
//    if (bus_if.read_data != old_data) begin
//        data_reg[word_count] <= bus_if.read_data[31:0];
//        data_reg[word_count+1]   <= bus_if.read_data[63:32];
//        word_count <= word_count+2;   
//        old_data <= bus_if.read_data;
//    end
//        
//    //if (word_count == 8) begin
//    //    
//    //end
//
//end

endtask : read_bus