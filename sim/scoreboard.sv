`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

`include "transaction.sv"

class scoreboard #(parameter DEPTH = 8, parameter DWIDTH = 16);
  mailbox #(transaction #(DWIDTH)) mon2scb;

  bit [DWIDTH-1:0] ref_queue[$];
  bit [DWIDTH-1:0] last_dout;

  int pass_count;
  int fail_count;
  int valid_wr_count;
  int valid_rd_count;
  int overflow_count;
  int underflow_count;

  function new(mailbox #(transaction #(DWIDTH)) mon2scb);
    this.mon2scb = mon2scb;
  endfunction

  task run();
    transaction #(DWIDTH) pkt;
    bit pre_empty, pre_full;
    bit exp_empty, exp_full;
    bit [DWIDTH-1:0] exp_data;

    forever begin
      mon2scb.get(pkt);

      if (pkt.rst) begin
        ref_queue.delete();
        last_dout = '0;
        continue;
      end

      // Capture pre-edge queue status
      pre_empty = (ref_queue.size() == 0);
      pre_full  = (ref_queue.size() == DEPTH);

      // 1. Check Read Side (Normal Read vs. Underflow)
      if (pkt.rd_en) begin
        if (!pre_empty) begin
          exp_data = ref_queue.pop_front();
          valid_rd_count++;

          if (pkt.data_out !== exp_data) begin
            $display("[SCB FAIL] %0t: Read mismatch! Got 0x%0h, Expected 0x%0h",
                     $time, pkt.data_out, exp_data);
            fail_count++;
          end else begin
            pass_count++;
          end
          last_dout = exp_data;
        end else begin
          // Underflow: data_out must hold its previous value
          underflow_count++;
          if (pkt.data_out !== last_dout) begin
            $display("[SCB FAIL] %0t: Underflow corrupted data_out! Got 0x%0h, Expected 0x%0h",
                     $time, pkt.data_out, last_dout);
            fail_count++;
          end else begin
            pass_count++;
          end
        end
      end

      // 2. Check Write Side (Normal Write vs. Overflow)
      if (pkt.wr_en) begin
        if (!pre_full) begin
          ref_queue.push_back(pkt.data_in);
          valid_wr_count++;
        end else begin
          // Overflow: write must be ignored
          overflow_count++;
        end
      end

      // 3. Check Post-Edge Empty and Full Flags
      exp_empty = (ref_queue.size() == 0);
      exp_full  = (ref_queue.size() == DEPTH);

      if (pkt.empty !== exp_empty) begin
        $display("[SCB FAIL] %0t: empty flag mismatch! Got %0b, Expected %0b (size=%0d)",
                 $time, pkt.empty, exp_empty, ref_queue.size());
        fail_count++;
      end else begin
        pass_count++;
      end

      if (pkt.full !== exp_full) begin
        $display("[SCB FAIL] %0t: full flag mismatch! Got %0b, Expected %0b (size=%0d)",
                 $time, pkt.full, exp_full, ref_queue.size());
        fail_count++;
      end else begin
        pass_count++;
      end
    end
  endtask

  function void report();
    $display("\n================ SCOREBOARD REPORT ================");
    $display("  Valid Writes        : %0d", valid_wr_count);
    $display("  Valid Reads         : %0d", valid_rd_count);
    $display("  Overflow Attempts   : %0d", overflow_count);
    $display("  Underflow Attempts  : %0d", underflow_count);
    $display("  Checks Passed       : %0d", pass_count);
    $display("  Checks Failed       : %0d", fail_count);
    $display("  Result              : %s", (fail_count == 0) ? "PASSED" : "FAILED");
    $display("===================================================\n");
  endfunction

endclass

`endif