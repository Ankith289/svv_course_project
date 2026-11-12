`ifndef TEST_SV
`define TEST_SV

`include "environment.sv"

program fifo_test #(
  parameter DEPTH  = 8,
  parameter DWIDTH = 16
)(
  fifo_interface intf
);

  environment #(DEPTH, DWIDTH) env;

  initial begin
    env = new(intf);
    env.run();
    $finish;
  end

endprogram

`endif