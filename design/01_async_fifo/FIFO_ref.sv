`timescale 1ns/1ps
`default_nettype none

// Reference asynchronous FIFO.
//
// Architecture:
//   * independent write and read clock domains;
//   * binary pointers address the storage array;
//   * Gray-coded pointers are the only multi-bit control values crossing CDC;
//   * each Gray pointer is synchronized through two destination-domain flops;
//   * full/empty are registered from the next local pointer value.
//
// Reset contract:
//   wrst_n and rrst_n are intended for a common power-on reset assertion.
//   Their deassertion must be synchronized to wclk and rclk respectively.
//   Resetting only one domain while traffic/data are live flushes the pointer
//   relationship and is therefore outside this module's supported contract.
module FIFO_ref #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned ADDR_WIDTH = 4
) (
    input  logic                  wclk,
    input  logic                  wrst_n,
    input  logic                  winc,
    input  logic [DATA_WIDTH-1:0] wdata,
    output logic                  wfull,

    input  logic                  rclk,
    input  logic                  rrst_n,
    input  logic                  rinc,
    output logic [DATA_WIDTH-1:0] rdata,
    output logic                  rempty
);

    localparam int unsigned DEPTH     = 1 << ADDR_WIDTH;
    localparam int unsigned PtrWidth = ADDR_WIDTH + 1;

    // In a Gray pointer, full is detected by inverting the two most
    // significant bits of the synchronized opposite-domain pointer.
    // Expressing this as an XOR mask also keeps ADDR_WIDTH=1 legal.
    localparam logic [PtrWidth-1:0] FullMask = {
        2'b11, {ADDR_WIDTH-1{1'b0}}
    };

    logic [DATA_WIDTH-1:0] mem [DEPTH];

    logic [PtrWidth-1:0] wbin;
    logic [PtrWidth-1:0] wbin_next;
    logic [PtrWidth-1:0] wgray;
    logic [PtrWidth-1:0] wgray_next;

    logic [PtrWidth-1:0] rbin;
    logic [PtrWidth-1:0] rbin_next;
    logic [PtrWidth-1:0] rgray;
    logic [PtrWidth-1:0] rgray_next;

    // These registers are asynchronous CDC synchronizer chains. The
    // attributes are advisory; CDC/STA constraints are still required.
    (* ASYNC_REG = "TRUE" *) logic [PtrWidth-1:0] rgray_wsync1;
    (* ASYNC_REG = "TRUE" *) logic [PtrWidth-1:0] rgray_wsync2;
    (* ASYNC_REG = "TRUE" *) logic [PtrWidth-1:0] wgray_rsync1;
    (* ASYNC_REG = "TRUE" *) logic [PtrWidth-1:0] wgray_rsync2;

    logic wpush;
    logic rpop;
    logic wfull_next;
    logic rempty_next;

    assign wpush = winc && !wfull;
    assign rpop  = rinc && !rempty;

    assign wbin_next  = wbin + wpush;
    assign wgray_next = (wbin_next >> 1) ^ wbin_next;
    assign wfull_next = (wgray_next == (rgray_wsync2 ^ FullMask));

    assign rbin_next   = rbin + rpop;
    assign rgray_next  = (rbin_next >> 1) ^ rbin_next;
    assign rempty_next = (rgray_next == wgray_rsync2);

    // Dual-clock storage. A full write and an empty read are ignored.
    always_ff @(posedge wclk) begin
        if (wpush) begin
            mem[wbin[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    // Standard registered-read interface: rdata changes only after an
    // accepted read (rinc && !rempty) and otherwise holds its last value.
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= '0;
        end else if (rpop) begin
            rdata <= mem[rbin[ADDR_WIDTH-1:0]];
        end
    end

    // Write pointer and full flag live entirely in the write domain.
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wbin  <= '0;
            wgray <= '0;
            wfull <= 1'b0;
        end else begin
            wbin  <= wbin_next;
            wgray <= wgray_next;
            wfull <= wfull_next;
        end
    end

    // Read pointer and empty flag live entirely in the read domain.
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rbin   <= '0;
            rgray  <= '0;
            rempty <= 1'b1;
        end else begin
            rbin   <= rbin_next;
            rgray  <= rgray_next;
            rempty <= rempty_next;
        end
    end

    // Synchronize the read Gray pointer into the write domain.
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rgray_wsync1 <= '0;
            rgray_wsync2 <= '0;
        end else begin
            rgray_wsync1 <= rgray;
            rgray_wsync2 <= rgray_wsync1;
        end
    end

    // Synchronize the write Gray pointer into the read domain.
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wgray_rsync1 <= '0;
            wgray_rsync2 <= '0;
        end else begin
            wgray_rsync1 <= wgray;
            wgray_rsync2 <= wgray_rsync1;
        end
    end

    initial begin
        if (DATA_WIDTH < 1) begin
            $fatal(1, "FIFO_ref: DATA_WIDTH must be at least 1");
        end
        if (ADDR_WIDTH < 1) begin
            $fatal(1, "FIFO_ref: ADDR_WIDTH must be at least 1 (DEPTH >= 2)");
        end
    end

endmodule

`default_nettype wire
