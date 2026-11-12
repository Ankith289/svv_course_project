module sync_fifo #(
  parameter DEPTH  = 8,
  parameter DWIDTH = 16
)(
  input                   rst,    // Active high reset
  input                   clk,    // Clock
  input                   wr_en,  // Write enable
  input                   rd_en,  // Read enable
  input      [DWIDTH-1:0] din,    // Data written into FIFO
  output reg [DWIDTH-1:0] dout,   // Data read from FIFO
  output                  empty,  // FIFO is empty when high
  output                  full    // FIFO is full when high
);

  localparam ADDR_WIDTH = $clog2(DEPTH);

  // Extra MSB bit tracks wrap-around so all DEPTH entries can be used
  reg [ADDR_WIDTH:0] wptr;
  reg [ADDR_WIDTH:0] rptr;

  reg [DWIDTH-1:0] fifo [0:DEPTH-1];

  // Write side
  always @(posedge clk) begin
    if (rst) begin
      wptr <= 0;
    end else if (wr_en && !full) begin
      fifo[wptr[ADDR_WIDTH-1:0]] <= din;
      wptr <= wptr + 1'b1;
    end
  end

  // Read side
  always @(posedge clk) begin
    if (rst) begin
      rptr <= 0;
      dout <= 0;
    end else if (rd_en && !empty) begin
      dout <= fifo[rptr[ADDR_WIDTH-1:0]];
      rptr <= rptr + 1'b1;
    end
  end

  // Status flags
  assign empty = (wptr == rptr);
  assign full  = (wptr[ADDR_WIDTH] != rptr[ADDR_WIDTH]) &&
                 (wptr[ADDR_WIDTH-1:0] == rptr[ADDR_WIDTH-1:0]);

endmodule
