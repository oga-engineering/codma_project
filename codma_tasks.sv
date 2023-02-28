/*
This will be used for the read and write tasks to improve the code...
eventually
*/

task read_bus(
    input [31:0]    reg_addr,
    input [3:0]     size,
    output [7:0][31:0]   data_reg
);

$display("read task");

assign bus_if.addr = reg_addr;

always_comb begin
    if (!bus_if.grant) begin
        bus_if.read = 1;
    end else begin
        bus_if.read = 0;
    end

    if (bus_if.read_valid) begin
        data_reg = read_data;
    end
end

endtask : read_bus