// This is the driver class for the CPU Verification Component
// The driver takes items from the sequences and replicates the procedures, thus driving the CPU interface bus

class cpu_driver extends uvm_driver#(cpu_instruction);

   `uvm_component_utils(cpu_driver)

   function new (string name, uvm_component parent);
      super.new(name, parent);
   endfunction

   // the cpu must write to both the mem and the dut
   virtual cpu_interface.master cpu_vif;
   virtual mem_interface.master mem_vif;

   task run_phase(uvm_phase phase);
      cpu_instruction cpu_instr;

      // Init clock and run continuously
      cpu_vif.clock = 0;
      always #2 cpu_vif.clock = ~cpu_vif.clock;

      // Setup Delay
      #4;

      forever begin
         `uvm_info(get_type_name(), "CPU Sequence next item",UVM_LOW)
         seq_item_port.get_next_item(cpu_instr);
         push_to_dut(cpu_instr);

         if(!cpu_vif.busy)
            wait(cpu_vif.busy)
         `uvm_info(get_type_name(),"The DUT has picked up the task",UVM_LOW)

         // Drop the start flag
         @(posedge cpu_vif.clock);
         cpu_vif.start = 0;

         // Once received done flag from DUT may confirm transaction done
         if(!cpu_vif.irq)
            wait (cpu_vif.irq);
         `uvm_info(get_type_name(),$sformatf("The DUT has completed the task; irq = %b",cpu_vif.irq),UVM_LOW)
         seq_item_port.item_done(cpu_instr);
      end
   endtask

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   // Drive the task addr and signals to the DUT
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   task push_to_dut(cpu_instruction ci);
      `uvm_info(get_type_name(),$sformatf("Pushing task addr %d and stat addr %d to DUT as pointers",ci.task_pointer, ci.status_pointer),UVM_DEBUG)
      @(posedge cpu_vif.clock);
      cpu_vif.task_pointer     = ci.task_pointer;
      cpu_vif.status_pointer   = ci.status_pointer;
      
      // Call the task to start
      cpu_vif.start   = 1;
      cpu_vif.stop    = 0;

   endtask  
endclass