`ifndef TRANSACTION_SV
`define TRANSACTION_SV

class transaction #(parameter DWIDTH = 16);
  // Stimulus fields
  rand bit              wr_en;
  rand bit              rd_en;
  rand bit [DWIDTH-1:0] data_in;

  // Observed fields (populated by monitor)
  bit              rst;
  bit [DWIDTH-1:0] data_out;
  bit              empty;
  bit              full;

  // Scenario label for debug logs
  string tag;

  function void display(string prefix = "");
    $display("[%s] tag=%s rst=%0b wr_en=%0b rd_en=%0b din=0x%0h | dout=0x%0h empty=%0b full=%0b",
             prefix, tag, rst, wr_en, rd_en, data_in, data_out, empty, full);
  endfunction

endclass

`endif