`include "../sourcecode/syn_fifo.v"
`include "fifo_interface.sv"
`include "fifo_program.sv"

module top;
  bit clk, rst;
  bit fin = 0;

  initial
    clk = 1'b0;
  always begin
    #5 clk = ~clk;
  end

  initial begin
    repeat (2) begin
      @(posedge clk) rst <= 1;
    end
    @(posedge clk) rst <= 0;
  end

  fifo_interface intf (clk);
  
  fifo DUT (
            .rst(rst),
            .clk(clk),
            .wr_en(intf.wr_en),
            .rd_en(intf.rd_en),
            .din(intf.data_in),
            .dout(intf.data_out),
            .empty(intf.empty),
            .full(intf.full)
           );
  
   fifo_program prog (interf);

endmodule
