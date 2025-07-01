// The testbench file is used to connect the interfaces from the VCs to the DUT
module ip_codma_tb_top;


   timeunit 1ns;
   timeprecision 1ns;

   `include "uvm_macros.svh"
   import uvm_pkg::*;
   import ip_codma_env_pkg::*;

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   // Instantiate the static parts of the testbench
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   bit clock, reset_n;

   mem_interface      mem_if();
   cpu_interface      cpu_if();

   // DUT
   ip_codma_top ip_codma_dut(
      reset_n_i,
      cpu_if.slave,
      mem_if.master
   );

   // Memory Model
   ip_mem_pipelined ip_memory_model(
      reset_n_i,
      mem_if.slave
   );

   // Clock and reset_n generator
   //
   initial begin

      // Configure the Agent VIF
      uvm_config_db#(virtual cpu_interface)::set(null, "*", "cpu_interface",cpu_if);
      uvm_config_db#(virtual mem_interface)::set(null, "*", "mem_interface",mem_if);

      $display("static reset sequence");
      reset_n = 0;
      
      fork begin
         run_test();
      end begin
         #8;
         reset_n = 1;
         end
      join
      uvm_top.set_timeout(1000us);
   end


endmodule
