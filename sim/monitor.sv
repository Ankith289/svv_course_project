`ifndef MONITOR_SV
`define MONITOR_SV

`include "transaction.sv"

class monitor #(parameter DWIDTH = 16);
  virtual fifo_interface #(DWIDTH) intf;
  mailbox #(transaction #(DWIDTH)) mon2scb;

  function new(virtual fifo_interface #(DWIDTH) intf,
               mailbox #(transaction #(DWIDTH)) mon2scb);
    this.intf    = intf;
    this.mon2scb = mon2scb;
  endfunction

  task run();
    transaction #(DWIDTH) pkt;

    forever begin
      @(posedge intf.clk);
      pkt = new();

      // Sample inputs seen by DUT at the active clock edge
      pkt.rst     = intf.rst;
      pkt.wr_en   = intf.wr_en;
      pkt.rd_en   = intf.rd_en;
      pkt.data_in = intf.data_in;

      // Wait #1 for DUT non-blocking assignments and flags to settle
      #1;
      pkt.data_out = intf.data_out;
      pkt.empty    = intf.empty;
      pkt.full     = intf.full;

      mon2scb.put(pkt);
    end
  endtask

endclass

`endif