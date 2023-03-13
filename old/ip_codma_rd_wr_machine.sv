module read_write_machine (
    input   need_read,
    input   need_write,
    
    input   word_count_rd,
    input   word_count_wr,

    input  [1:0]  read_state_t,
    input  [1:0]  write_state_t,
    input  [1:0]  rd_state_r,
    input  [1:0]  wr_state_r,
    output [1:0]  rd_state_next_o,
    output [1:0]  wr_state_next_o,

    BUS_IF.master	bus_if,

    input   RD_IDLE,
    input   RD_ASK,
    input   RD_GRANTED,    

    input   WR_IDLE,
    input   WR_ASK,
    input   WR_GRANTED    
);

logic [1:0]  rd_state_next_s;
logic [1:0]  wr_state_next_s;

assign rd_state_next_o = rd_state_next_s;
assign wr_state_next_o = wr_state_next_s;

always_comb begin

    //--------------------------------------------------
    // DEFAULTS
    //--------------------------------------------------
    rd_state_next_s     = rd_state_r;
    wr_state_next_s     = wr_state_r;

    //--------------------------------------------------
    // READ PHASE STATE MACHINE
    //--------------------------------------------------
    case(rd_state_r)
        RD_IDLE:
        begin
            // DEFAULT VALUES
            if (need_read) begin
                rd_state_next_s = RD_ASK;
            end
        end
        // A READ HAS BEEN REQUESTED
        RD_ASK:
        begin
            if (bus_if.grant) begin
                rd_state_next_s = RD_GRANTED;
            end
        end
        // THE READ IS GRANTED
        RD_GRANTED:
        begin
            // CONDITIONS TO LEAVE THE READING STATE
            if (bus_if.size == 9 && word_count_rd == 8) begin
                rd_state_next_s = RD_IDLE;
            end
            if (bus_if.error) begin
                rd_state_next_s = RD_IDLE;
            end
        end
    endcase

    //--------------------------------------------------
    // WRITE PHASE STATE MACHINE
    //--------------------------------------------------
    case(wr_state_r)
        WR_IDLE:
        begin
            if (need_write) begin
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
            // CONDITIONS TO LEAVE THE WRITING STATE
            if (bus_if.size == 9 && word_count_wr == 8) begin
                wr_state_next_s = WR_IDLE;
            end
            if (bus_if.error) begin
                wr_state_next_s = WR_IDLE;
            end
        end
    endcase
end
endmodule