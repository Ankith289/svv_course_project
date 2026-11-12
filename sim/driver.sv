`ifndef DRIVER_SV
`define DRIVER_SV

`include "transaction.sv"

class driver #(parameter DWIDTH = 16);
  virtual fifo_interface #(DWIDTH) intf;
  mailbox #(transaction #(DWIDTH)) gen2drv;

  function new(virtual fifo_interface #(DWIDTH) intf,
               mailbox #(transaction #(DWIDTH)) gen2drv);
    this.intf    = intf;
    this.gen2drv = gen2drv;
  endfunction

  task run();
    transaction #(DWIDTH) pkt;

    // Initialize inputs to safe idle state
    intf.wr_en   <= 1'b0;
    intf.rd_en   <= 1'b0;
    intf.data_in <= '0;

    // Wait until reset is deasserted
    wait (intf.rst == 1'b0);

    forever begin
      gen2drv.get(pkt);
      @(posedge intf.clk);
      intf.wr_en   <= pkt.wr_en;
      intf.rd_en   <= pkt.rd_en;
      intf.data_in <= pkt.data_in;
    end
  endtask

endclass

`endif