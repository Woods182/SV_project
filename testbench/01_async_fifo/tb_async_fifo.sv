`timescale 1ns/1ps
`default_nettype none

module tb_async_fifo;

    parameter int unsigned DATA_WIDTH = 8;
    parameter int unsigned ADDR_WIDTH = 3;
    localparam int unsigned DEPTH      = 1 << ADDR_WIDTH;
    localparam int unsigned PtrWidth  = ADDR_WIDTH + 1;

    logic                  wclk;
    logic                  wrst_n;
    logic                  winc;
    logic [DATA_WIDTH-1:0] wdata;
    logic                  wfull;

    logic                  rclk;
    logic                  rrst_n;
    logic                  rinc;
    logic [DATA_WIDTH-1:0] rdata;
    logic                  rempty;

    realtime wclk_half_period = 5.0;
    realtime rclk_half_period = 6.5;

    logic [DATA_WIDTH-1:0] expected_q[$];
    logic [PtrWidth-1:0]   previous_wgray;
    logic [PtrWidth-1:0]   previous_rgray;
    int unsigned           accepted_writes;
    int unsigned           accepted_reads;
    int unsigned           error_count;

    FIFO #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) dut (
        .wclk,
        .wrst_n,
        .winc,
        .wdata,
        .wfull,
        .rclk,
        .rrst_n,
        .rinc,
        .rdata,
        .rempty
    );

    initial begin : waveform_dump
        $dumpfile("./out/01_async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);
    end

    initial begin
        wclk = 1'b0;
        forever #(wclk_half_period) wclk = ~wclk;
    end

    initial begin
        rclk = 1'b0;
        #2.0;
        forever #(rclk_half_period) rclk = ~rclk;
    end

    function automatic int unsigned count_ones(
        input logic [PtrWidth-1:0] value
    );
        int unsigned result;
        result = 0;
        for (int unsigned i = 0; i < PtrWidth; i++) begin
            result = result + (value[i] ? 1 : 0);
        end
        return result;
    endfunction

    task automatic report_error(input string message);
        error_count++;
        $error("%0t: %s", $time, message);
    endtask

    // The scoreboard records only requests accepted at the local interface.
    always @(posedge wclk) begin
        if (wrst_n && winc && !wfull) begin
            expected_q.push_back(wdata);
            accepted_writes++;
            if (expected_q.size() > DEPTH) begin
                report_error($sformatf(
                    "scoreboard occupancy %0d exceeds DEPTH=%0d",
                    expected_q.size(), DEPTH
                ));
            end
        end
    end

    always @(posedge rclk) begin : read_scoreboard
        logic [DATA_WIDTH-1:0] expected;

        if (rrst_n && rinc && !rempty) begin
            #0.001;
            accepted_reads++;
            if (expected_q.size() == 0) begin
                report_error($sformatf(
                    "read accepted with an empty scoreboard, rdata=0x%0h", rdata
                ));
            end else begin
                expected = expected_q.pop_front();
                if (rdata !== expected) begin
                    report_error($sformatf(
                        "data mismatch: expected=0x%0h actual=0x%0h",
                        expected, rdata
                    ));
                end
            end
        end
    end

    // Structural checks: a locally advancing Gray pointer may change at most
    // one bit, and no pointer may advance on a rejected request.
    always @(posedge wclk) begin : write_domain_checks
        logic [PtrWidth-1:0] old_wgray;
        logic                 request_was_blocked;

        old_wgray          = dut.wgray;
        request_was_blocked = wrst_n && winc && wfull;
        #0.001;

        if (wrst_n) begin
            if ($isunknown(wfull)) begin
                report_error("wfull contains X/Z");
            end
            if (count_ones(previous_wgray ^ dut.wgray) > 1) begin
                report_error($sformatf(
                    "write Gray pointer changed by more than one bit: %0h -> %0h",
                    previous_wgray, dut.wgray
                ));
            end
            if (request_was_blocked && (dut.wgray !== old_wgray)) begin
                report_error("write pointer advanced while full");
            end
            previous_wgray = dut.wgray;
        end
    end

    always @(posedge rclk) begin : read_domain_checks
        logic [PtrWidth-1:0] old_rgray;
        logic                 request_was_blocked;

        old_rgray          = dut.rgray;
        request_was_blocked = rrst_n && rinc && rempty;
        #0.001;

        if (rrst_n) begin
            if ($isunknown(rempty)) begin
                report_error("rempty contains X/Z");
            end
            if (count_ones(previous_rgray ^ dut.rgray) > 1) begin
                report_error($sformatf(
                    "read Gray pointer changed by more than one bit: %0h -> %0h",
                    previous_rgray, dut.rgray
                ));
            end
            if (request_was_blocked && (dut.rgray !== old_rgray)) begin
                report_error("read pointer advanced while empty");
            end
            previous_rgray = dut.rgray;
        end
    end

    task automatic wait_wclk(input int unsigned cycles);
        repeat (cycles) @(posedge wclk);
        #0.002;
    endtask

    task automatic wait_rclk(input int unsigned cycles);
        repeat (cycles) @(posedge rclk);
        #0.002;
    endtask

    task automatic reset_fifo;
        winc  = 1'b0;
        rinc  = 1'b0;
        wdata = '0;
        wrst_n = 1'b0;
        rrst_n = 1'b0;
        expected_q.delete();
        previous_wgray = '0;
        previous_rgray = '0;

        fork
            wait_wclk(4);
            wait_rclk(4);
        join

        // Release away from active clock edges; in hardware these releases
        // must be synchronized separately to their destination domains.
        @(negedge wclk);
        wrst_n = 1'b1;
        @(negedge rclk);
        rrst_n = 1'b1;

        fork
            wait_wclk(3);
            wait_rclk(3);
        join

        if (wfull !== 1'b0) report_error("wfull must be 0 after reset");
        if (rempty !== 1'b1) report_error("rempty must be 1 after reset");
    endtask

    task automatic write_word(input logic [DATA_WIDTH-1:0] value);
        bit accepted;

        accepted = 1'b0;
        @(negedge wclk);
        wdata = value;
        winc  = 1'b1;
        while (!accepted) begin
            @(posedge wclk);
            accepted = !wfull;
        end
        @(negedge wclk);
        winc = 1'b0;
    endtask

    task automatic read_word;
        bit accepted;

        accepted = 1'b0;
        @(negedge rclk);
        rinc = 1'b1;
        while (!accepted) begin
            @(posedge rclk);
            accepted = !rempty;
        end
        @(negedge rclk);
        rinc = 1'b0;
    endtask

    task automatic write_sequence(
        input int unsigned count,
        input logic [DATA_WIDTH-1:0] base,
        input bit random_stalls
    );
        for (int unsigned i = 0; i < count; i++) begin
            if (random_stalls) begin
                wait_wclk($urandom_range(0, 3));
            end
            write_word(base + i[DATA_WIDTH-1:0]);
        end
    endtask

    task automatic read_sequence(
        input int unsigned count,
        input bit random_stalls
    );
        for (int unsigned i = 0; i < count; i++) begin
            if (random_stalls) begin
                wait_rclk($urandom_range(0, 4));
            end
            read_word();
        end
    endtask

    task automatic test_empty_read_blocking;
        logic [DATA_WIDTH-1:0] held_rdata;
        int unsigned           reads_before;

        $display("[TEST] empty-read blocking");
        held_rdata   = rdata;
        reads_before = accepted_reads;
        @(negedge rclk);
        rinc = 1'b1;
        wait_rclk(5);
        @(negedge rclk);
        rinc = 1'b0;

        if (accepted_reads != reads_before) begin
            report_error("an empty read was accepted");
        end
        if (rdata !== held_rdata) begin
            report_error("rdata changed during rejected empty reads");
        end
    endtask

    task automatic test_fill_full_and_drain;
        int unsigned writes_before;

        $display("[TEST] fill/full blocking/drain");
        for (int unsigned i = 0; i < DEPTH; i++) begin
            write_word(8'h20 + i[DATA_WIDTH-1:0]);
        end
        #0.002;
        if (wfull !== 1'b1) begin
            report_error("wfull did not assert after DEPTH accepted writes");
        end

        writes_before = accepted_writes;
        @(negedge wclk);
        wdata = 8'hee;
        winc  = 1'b1;
        wait_wclk(5);
        @(negedge wclk);
        winc = 1'b0;
        if (accepted_writes != writes_before) begin
            report_error("a full write was accepted");
        end

        read_sequence(DEPTH, 1'b0);
        wait_rclk(2);
        if (rempty !== 1'b1) begin
            report_error("rempty did not assert after draining the FIFO");
        end
        if (expected_q.size() != 0) begin
            report_error("scoreboard is not empty after drain");
        end
    endtask

    task automatic run_concurrent_phase(
        input string phase_name,
        input int unsigned count,
        input logic [DATA_WIDTH-1:0] base
    );
        $display("[TEST] %s", phase_name);
        fork
            write_sequence(count, base, 1'b1);
            read_sequence(count, 1'b1);
        join

        wait_rclk(3);
        if (expected_q.size() != 0) begin
            report_error($sformatf(
                "%s ended with %0d queued words",
                phase_name, expected_q.size()
            ));
        end
        if (rempty !== 1'b1) begin
            report_error($sformatf("%s did not finish empty", phase_name));
        end
    endtask

    initial begin : timeout_watchdog
        #500000;
        $fatal(1, "tb_async_fifo timeout");
    end

    initial begin : test_sequence
        int unsigned seed;

        seed = 32'hf1f0_2026;
        seed = $urandom(seed);
        $display("tb_async_fifo seed=0x%08h depth=%0d", seed, DEPTH);

        accepted_writes = 0;
        accepted_reads  = 0;
        error_count     = 0;
        wrst_n          = 1'b0;
        rrst_n          = 1'b0;
        winc            = 1'b0;
        rinc            = 1'b0;
        wdata           = '0;
        previous_wgray  = '0;
        previous_rgray  = '0;

        reset_fifo();
        test_empty_read_blocking();
        test_fill_full_and_drain();

        // Write clock faster than read clock; enough transfers for repeated
        // wrap-around and multiple full/empty transitions.
        wclk_half_period = 4.0;
        rclk_half_period = 7.0;
        run_concurrent_phase("write-fast/read-slow randomized traffic",
                             DEPTH * 6, 8'h40);

        // Read clock faster than write clock.
        wclk_half_period = 8.0;
        rclk_half_period = 3.5;
        run_concurrent_phase("write-slow/read-fast randomized traffic",
                             DEPTH * 6, 8'h80);

        // Similar frequencies with unrelated phase.
        wclk_half_period = 5.5;
        rclk_half_period = 5.0;
        run_concurrent_phase("near-frequency randomized traffic",
                             DEPTH * 5, 8'hc0);

        if ((error_count == 0) &&
            (accepted_writes == accepted_reads) &&
            (expected_q.size() == 0)) begin
            $display(
                "PASS: writes=%0d reads=%0d final_occupancy=%0d",
                accepted_writes, accepted_reads, expected_q.size()
            );
            $finish;
        end

        $fatal(1,
            "FAIL: errors=%0d writes=%0d reads=%0d occupancy=%0d",
            error_count, accepted_writes, accepted_reads, expected_q.size()
        );
    end

endmodule

`default_nettype wire
