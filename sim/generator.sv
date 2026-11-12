`ifndef GENERATOR_SV
`define GENERATOR_SV

`include "transaction.sv"

class generator #(parameter DEPTH = 8, parameter DWIDTH = 16);
  mailbox #(transaction #(DWIDTH)) gen2drv;

  function new(mailbox #(transaction #(DWIDTH)) gen2drv);
    this.gen2drv = gen2drv;
  endfunction

  // Base helper to build and send a single transaction
  task send_txn(bit wr, bit rd, bit [DWIDTH-1:0] din, string tag);
    transaction #(DWIDTH) pkt = new();
    pkt.wr_en   = wr;
    pkt.rd_en   = rd;
    pkt.data_in = din;
    pkt.tag     = tag;
    gen2drv.put(pkt);
  endtask

  // 1. Perform 'count' normal write operations
  task write(int count = 4, bit [DWIDTH-1:0] base_data = 16'h1000);
    $display("[GEN] Running write(%0d)...", count);
    for (int i = 0; i < count; i++) begin
      send_txn(1'b1, 1'b0, base_data + i, "WRITE");
    end
  endtask

  // 2. Perform 'count' normal read operations
  task read(int count = 4);
    $display("[GEN] Running read(%0d)...", count);
    for (int i = 0; i < count; i++) begin
      send_txn(1'b0, 1'b1, '0, "READ");
    end
  endtask

  // 3. Perform 'count' simultaneous read & write operations
  task read_write(int count = 2, bit [DWIDTH-1:0] base_data = 16'h2000);
    $display("[GEN] Running read_write(%0d)...", count);
    for (int i = 0; i < count; i++) begin
      send_txn(1'b1, 1'b1, base_data + i, "SIMUL_RW");
    end
  endtask

  // 4. Fill FIFO to DEPTH, attempt 'extra_writes' overflows, then drain
  task overflow(int extra_writes = 3, bit drain_after = 1);
    $display("[GEN] Running overflow(extra_writes=%0d)...", extra_writes);
    for (int i = 0; i < DEPTH; i++) begin
      send_txn(1'b1, 1'b0, 16'h3000 + i, "OVF_FILL");
    end
    for (int i = 0; i < extra_writes; i++) begin
      send_txn(1'b1, 1'b0, 16'hDEAD, "OVERFLOW");
    end
    if (drain_after) begin
      for (int i = 0; i < DEPTH; i++) begin
        send_txn(1'b0, 1'b1, '0, "OVF_DRAIN");
      end
    end
  endtask

  // 5. Attempt 'extra_reads' on an empty FIFO, then verify pointer recovery
  task underflow(int extra_reads = 3, bit recover_after = 1);
    $display("[GEN] Running underflow(extra_reads=%0d)...", extra_reads);
    for (int i = 0; i < extra_reads; i++) begin
      send_txn(1'b0, 1'b1, '0, "UNDERFLOW");
    end
    if (recover_after) begin
      send_txn(1'b1, 1'b0, 16'h55AA, "UDF_RECOVER_WR");
      send_txn(1'b0, 1'b1, '0,       "UDF_RECOVER_RD");
    end
  endtask

  // 6. Perform 'count' constrained-random transactions
  task random_ops(int count = 50);
    transaction #(DWIDTH) rnd_pkt;
    $display("[GEN] Running random_ops(%0d)...", count);
    repeat (count) begin
      rnd_pkt = new();
      assert(rnd_pkt.randomize());
      rnd_pkt.tag = "RANDOM";
      gen2drv.put(rnd_pkt);
    end
  endtask

  // 7. Insert 'count' idle cycles
  task idle(int count = 1);
    repeat (count) begin
      send_txn(1'b0, 1'b0, '0, "IDLE");
    end
  endtask

  // -------------------------------------------------------------------------
  // Main Run Task: Add, remove, or change counts here to customize your test
  // -------------------------------------------------------------------------
  task run();
    // Normal operations
    write(4);
    read_write(2);
    read(4);
    idle(1);

    // Overflow scenario (fills 8 slots + attempts 3 extra writes + drains 8)
    overflow(3);
    idle(1);

    // Underflow scenario (attempts 3 reads while empty + 1 write/read recovery)
    underflow(3);
    idle(1);

    // Random stress traffic
    random_ops(50);
    idle(2);

    $display("[GEN] All generator tasks completed.");
  endtask

endclass

`endif