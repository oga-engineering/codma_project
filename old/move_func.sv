/*
Move package to define the move task.
May be better to use as functions and not a package for debug.
*/

`include "bus_interface.sv"
// Task type 0: copy N bytes from Address A to Address B
task move_0 (
    input logic [31:0]  task_pointer_i
);
    $display("move 0 - testing message");
endtask : move_0