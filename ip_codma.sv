//`include "codma_tasks.sv"
module ip_codma(

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

// --------------------------------------
// Internal registers
//logic [31:0] reg_task_pointer;
logic new_task;
logic [7:0][31:0] task_data;
logic [7:0] word_count;
logic [63:0] old_data;
// --------------------------------------


always @(posedge clk_i, reset_n_i ) begin

    // Reset Conditions
    if (!reset_n_i) begin
        busy_o              <= 'd0;
        irq_o               <= 'd0;
        //reg_task_pointer    <= 'd0;
        //new_task            <= 'd0;
        word_count          <= 'd0;
        task_data           <= 'd0;
        old_data            <= 'd0;

    end else begin
        //Determine sample
        if (!busy_o && start_i) begin
            //Sample task pointer
            //reg_task_pointer <= task_pointer_i;
            new_task    <= 'd1;
            busy_o      <= 'd1;
            bus_if.read <= 1;
            bus_if.addr <= task_pointer_i;
            bus_if.size <= 'd9;
            word_count  <= 'd0;
            task_data   <= 'd0;
        end

        //deassert the read/write req
        if (bus_if.grant) begin
            bus_if.read  <= 0;
            bus_if.write <= 0;
        end
        
        //Start saving the data
        if (bus_if.read_valid)begin
            if (bus_if.read_data != old_data) begin
                word_count <= word_count+2;
            end
            task_data[word_count] <= bus_if.read_data[31:0];
            task_data[word_count+1]   <= bus_if.read_data[63:32];
            old_data <= bus_if.read_data;
        end
        

    end
end




















endmodule
