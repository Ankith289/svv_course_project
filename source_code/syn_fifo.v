module sync_fifo #(parameter DEPTH=8, DWIDTH=16)
(
        input rst,               // Active low reset
        input clk,                // Clock
        input wr_en, 				// Write enable
        input rd_en, 				// Read enable
        input [DWIDTH-1:0] din, 				// Data written into FIFO
        output  reg [DWIDTH-1:0] dout, 				// Data read from FIFO
        output  empty, 				// FIFO is empty when high
        output  full 				// FIFO is full when high
);


  reg [$clog2(DEPTH)-1:0]   wptr;         // Write address, wraps at DEPTH
  reg [$clog2(DEPTH)-1:0]   rptr;         // Read address, wraps at DEPTH

  reg [DWIDTH-1 : 0]    fifo[0:DEPTH-1];  // Storage

  // Write side: store din and advance the write pointer
  always @ (posedge clk) begin
    if (rst) begin
      wptr <= 0;
    end else begin
      if (wr_en & !full) begin
        fifo[wptr] <= din;
        wptr <= wptr + 1;
      end
    end
  end

  // Read side: output the oldest word and advance the read pointer
  always @ (posedge clk) begin
    if (rst) begin
      rptr <= 0;
    end else begin
      if (rd_en & !empty) begin
        dout <= fifo[rptr];
        rptr <= rptr + 1;
      end
    end
  end

  // Flags: full when one more write would make the pointers equal
  assign full  = (wptr + 1'b1) == rptr;
  assign empty = wptr == rptr;
endmodule
