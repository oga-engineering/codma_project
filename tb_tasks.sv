// Set of tasks used by the testbench
task setup_data(
    input [31:0]    task_pointer,
    input [31:0]    task_type,
    input [31:0]    len_bytes,
    output [31:0]   source_addr_o,
    output [31:0]   dest_addr_o,
    output [31:0]   source_addr_l,
    output [31:0]   dest_addr_l,
    output [31:0]   task_type_l,
    output [31:0]   len_bytes_l,
    output [31:0][7:0][7:0] int_mem
    );
    begin
	    logic [31:0] source_addr;
	    logic [31:0] dest_addr;

        // this randomisation method needs refining. May causes clashes.
        source_addr     = $urandom_range(0,(inst_mem.MEM_DEPTH-4))*inst_mem.MEM_WIDTH;
        source_addr_o   = source_addr;
        // add +32 so it doesn not overwrite the linked task. Not the smartest way, but it works
        dest_addr       = ($urandom_range(0,(inst_mem.MEM_DEPTH-4))*inst_mem.MEM_WIDTH)+32;
        dest_addr_o     = dest_addr;

        // assign to shape for memory module
        inst_mem.mem_array[(task_pointer/inst_mem.MEM_WIDTH)] = {source_addr,task_type};
        inst_mem.mem_array[((task_pointer/inst_mem.MEM_WIDTH)+1)] = {len_bytes,dest_addr};

        // Make a copy of the mem_array before changes (avoid overlap verification issues)
        int_mem = inst_mem.mem_array;

        // SETUP A LINK TASK 
        if (task_type == 'd2) begin
            source_addr     = $urandom_range(0,(inst_mem.MEM_DEPTH-4))*inst_mem.MEM_WIDTH;
            source_addr_l   = source_addr;
            dest_addr       = ($urandom_range(0,(inst_mem.MEM_DEPTH-4))*inst_mem.MEM_WIDTH);
            dest_addr_l     = dest_addr;
            task_type_l     = $urandom_range(1,1);
            if (task_type_l == 'd0) begin
                len_bytes_l     = ($urandom_range(1,4)*8);
            end else begin
                len_bytes_l = ($urandom_range(1,3)*32);
            end
            inst_mem.mem_array[(task_pointer/inst_mem.MEM_WIDTH)+4] = {source_addr,task_type_l};
            inst_mem.mem_array[((task_pointer/inst_mem.MEM_WIDTH)+5)] = {len_bytes_l,dest_addr};
        end else begin
            source_addr_l   = 'd0;
			dest_addr_l     = 'd0;
            len_bytes_l     = 'd0;
            task_type_l     = 'd0;
        end
        

    end
endtask

task check_data(
    input [31:0] source_addr_o,
    input [31:0] dest_addr_o,
    input [31:0] source_addr_l,
    input [31:0] dest_addr_l,
    input [31:0] task_type,
    input [31:0] len_bytes,
    input [31:0] task_type_l,
    input [31:0] len_bytes_l,
    input [31:0][7:0][7:0] int_mem
    );
    // ALL _L INPUTS ARE FOR LINKED TASKS
    begin
        logic [31:0] src_location;
        logic [31:0] dst_location;
        
        $display("//-------------------------------------------------------------------------------------------------------",task_type);
        $display("Begin Check: task type %d",task_type);

        

        src_location = source_addr_o/inst_mem.MEM_WIDTH;
        dst_location = dest_addr_o/inst_mem.MEM_WIDTH;
        #50
        if (task_type == 'd0) begin
            for (int i=0; i<(len_bytes/8); i++ ) begin
                if (int_mem[src_location] === inst_mem.mem_array[dst_location]) begin
                    pass_message(task_type, len_bytes,i);
                    src_location = src_location + i;
                    dst_location = dst_location + i;
                end else begin
                    fail_message(len_bytes, task_type, src_location, dst_location);
                    src_location = src_location + i;
                    dst_location = dst_location + i;
                end
            end
        end else if (task_type == 'd1) begin
            for (int i=0; i<(len_bytes/32); i++ ) begin
                if (int_mem[src_location] === inst_mem.mem_array[dst_location]) begin
                    pass_message(task_type, len_bytes,i);
                    src_location = src_location + i;
                    dst_location = dst_location + i;
                end else begin
                    fail_message(len_bytes, task_type, src_location, dst_location);
                    src_location = src_location + i;
                    dst_location = dst_location + i;
                end
            end
        end else if (task_type == 'd2) begin
            for (int i=0; i<(len_bytes/32); i++ ) begin
                if (int_mem[src_location] === inst_mem.mem_array[dst_location]) begin
                    pass_message(task_type, len_bytes,i);
                    src_location = src_location + i;
                    dst_location = dst_location + i;
                end else begin
                    fail_message(len_bytes, task_type, src_location, dst_location);
                    src_location = src_location + i;
                    dst_location = dst_location + i;
                end
            end
            // check the linked task
            $display("Check Linked Task: task type %d",task_type_l);
            check_data(
				source_addr_l,   //source_addr_o,
				dest_addr_l,     //dest_addr_o,
                'd0,             //source_addr_l,
                'd0,             //dest_addr_l,
                task_type_l,     //task_type,
				len_bytes_l,     //len_bytes,
                'd0,             //task_type_l,
                'd0,             //len_bytes_l,
				int_mem         //int_mem
			);
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
        if (task_type == 'd0) begin
            transf = (i+1) * 'd8;
        end else if (task_type == 'd1) begin
            transf = (i+1) * 'd32;
        end else if (task_type == 'd2) begin
            transf = (i+1) * 'd32;
        end
        $display("Bytes transfered %d of %d: SUCCESS", transf, len_bytes);
    end
endtask