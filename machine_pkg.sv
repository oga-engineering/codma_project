package read_pkg;
    typedef enum logic [1:0]
        {
          RD_IDLE	    = 2'b00,				 
          RD_ASK 	    = 2'b01,
          RD_GRANTED	= 2'b10
        }
        read_state_t;
endpackage

package write_pkg;
    typedef enum logic [1:0]
    {
      WR_IDLE	    = 2'b00,				 
      WR_ASK 	    = 2'b01,
      WR_GRANTED	= 2'b10
    }
    write_state_t;
endpackage

package dma_pkg;
    typedef enum logic [2:0]
    {
      DMA_IDLE	    = 3'b000,				 
      DMA_PENDING   = 3'b001,
      DMA_TASK_READ = 3'b010,
      DMA_DATA_READ	= 3'b011,
      //DMA_COMPUTE   = 3'b110,
      DMA_WRITING   = 3'b101
    }
    dma_state_t;
endpackage