`ifndef FIFO_INTERFACE_SV
`define FIFO_INTERFACE_SV

interface fifo_interface #(
  parameter DWIDTH = 16
)(
  input logic clk,
  input logic rst
);

  logic              wr_en;
  logic              rd_en;
  logic [DWIDTH-1:0] data_in;
  logic [DWIDTH-1:0] data_out;
  logic              empty;
  logic              full;

endinterface

`endif