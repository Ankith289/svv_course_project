`ifndef ENVIRONMENT_SV
`define ENVIRONMENT_SV

`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"

class environment #(parameter DEPTH = 8, parameter DWIDTH = 16);
  virtual fifo_interface #(DWIDTH) intf;

  generator  #(DEPTH, DWIDTH) gen;
  driver     #(DWIDTH)        drv;
  monitor    #(DWIDTH)        mon;
  scoreboard #(DEPTH, DWIDTH) scb;

  mailbox #(transaction #(DWIDTH)) gen2drv;
  mailbox #(transaction #(DWIDTH)) mon2scb;

  function new(virtual fifo_interface #(DWIDTH) intf);
    this.intf = intf;

    // Bounded size-1 mailbox keeps generator synchronized with driver
    gen2drv = new(1);
    mon2scb = new();

    gen = new(gen2drv);
    drv = new(intf, gen2drv);
    mon = new(intf, mon2scb);
    scb = new(mon2scb);
  endfunction

  task run();
    fork
      gen.run();
      drv.run();
      mon.run();
      scb.run();
    join_any

    // Allow final driven transaction to propagate through monitor and scoreboard
    repeat (3) @(posedge intf.clk);
    #2;

    scb.report();
  endtask

endclass

`endif