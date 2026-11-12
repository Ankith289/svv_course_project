`include "../sourcecode/syn_fifo.v"
`include "fifo_interface.sv"
`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "environment.sv"
`include "test.sv"

module top;
  parameter DEPTH  = 8;
  parameter DWIDTH = 16;

  bit clk, rst;

  // Clock generation (10ns period)
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // Active-high reset generation
  initial begin
    rst = 1'b1;
    repeat (2) @(posedge clk);
    @(posedge clk) rst <= 1'b0;
  end

  // Interface instantiation
  fifo_interface #(.DWIDTH(DWIDTH)) intf (
    .clk(clk),
    .rst(rst)
  );

  // DUT instantiation
  sync_fifo #(
    .DEPTH(DEPTH),
    .DWIDTH(DWIDTH)
  ) DUT (
    .rst   (rst),
    .clk   (clk),
    .wr_en (intf.wr_en),
    .rd_en (intf.rd_en),
    .din   (intf.data_in),
    .dout  (intf.data_out),
    .empty (intf.empty),
    .full  (intf.full)
  );

  // Test program instantiation
  fifo_test #(
    .DEPTH(DEPTH),
    .DWIDTH(DWIDTH)
  ) test (intf);

endmodule
