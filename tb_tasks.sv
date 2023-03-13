// Set of tasks used by the testbench

task setup_data(
    input           clk,
    input [31:0]    task_pointer,
    input [31:0]    task_type,
    input [31:0]    len_bytes,
    output [31:0]   source_addr_o,
    output [31:0]   dest_addr_o,
    output [7:0][31:0] int_mem
    );
    begin
	    logic [31:0] source_addr;
	    logic [31:0] dest_addr;

        // this randomisation method needs refining. May causes clashes.
        source_addr     = $urandom_range(0,(inst_mem.MEM_DEPTH-4))*inst_mem.MEM_WIDTH;
        source_addr_o   = source_addr;
        dest_addr       = $urandom_range(0,(inst_mem.MEM_DEPTH-4))*inst_mem.MEM_WIDTH;
        dest_addr_o     = dest_addr;

        // assign to shape for memory module
        inst_mem.mem_array[(task_pointer/inst_mem.MEM_WIDTH)] = {source_addr,task_type};
        inst_mem.mem_array[((task_pointer/inst_mem.MEM_WIDTH)+1)] = {len_bytes,dest_addr};

        // Make a copy of the mem_array before changes (avoid overlap verification issues)
        int_mem = inst_mem.mem_array;
        

    end
endtask

task check_data(
    input [31:0] source_addr_o,
    input [31:0] dest_addr_o,
    input [31:0] task_type,
    input [31:0] len_bytes,
    input [7:0][31:0] int_mem
    );
    begin
        logic [31:0] src_location;
        logic [31:0] dst_location;

        src_location = source_addr_o/inst_mem.MEM_WIDTH;
        dst_location = dest_addr_o/inst_mem.MEM_WIDTH;

        if (task_type == 'd0) begin
            for (int i=0; i<(len_bytes/8); i++ ) begin
                if (int_mem[src_location+i] === int_mem[dst_location+i]) begin
                    pass_message(task_type, len_bytes,i);
                end else begin
                    fail_message(len_bytes, task_type, src_location, dst_location);
                end
            end
        end
    end
endtask

task fail_message(
    input [31:0] len_bytes,
    input [31:0] task_type,
    input [31:0] src_location,
    input [31:0] dst_location
    );
    begin
    $display("test failed: test type %d ; len_bytes %d", task_type, len_bytes);
    $display("src content %h, at location %d",inst_mem.mem_array[src_location], src_location);
    $display("dst content %h, at location %d",inst_mem.mem_array[dst_location], dst_location);
    $stop;
    end
endtask

task pass_message(
    input [31:0] task_type,
    input [31:0] len_bytes,
    input int    i
    );
    logic [31:0] transf;
    begin
        $display("Test Type %d", task_type);
        if (task_type == 'd0) begin
            transf = (i+1) * 'd8;
        end else if (task_type == 'd1) begin
            transf = (i+1) * 'd32;
        end
        $display("Bytes transfered %d of %d: SUCCESS", transf, len_bytes);
    end
endtask