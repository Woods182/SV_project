module FIFO # (
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
    localparam int unsigned DEPTH    = 1 << ADDR_WIDTH;
    localparam int unsigned PtrWidth = ADDR_WIDTH + 1;


    //  指针同步打两拍
    logic [PtrWidth-1:0] wbin,rbin,rgray,wgray;
    logic [PtrWidth-1:0] wgray_rsync1, wgray_rsync2;
    logic [PtrWidth-1:0] rgray_wsync1, rgray_wsync2;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wgray_rsync1 <= '0;
            wgray_rsync2 <= '0;

        end else begin
            wgray_rsync1 <= wgray;
            wgray_rsync2 <= wgray_rsync1;

        end

    end


    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rgray_wsync1 <= '0;
            rgray_wsync2 <= '0;

        end else begin
            rgray_wsync1 <= rgray;
            rgray_wsync2 <= rgray_wsync1;

        end

    end

    logic [PtrWidth-1:0] rgray_next,wgray_next;
    logic [PtrWidth-1:0] wbin_next,rbin_next;
    logic rempty_next,wfull_next;

    // 转换grey 码
    assign rgray_next = (rbin_next >> 1) ^ rbin_next;
    assign wgray_next = wbin_next ^ (wbin_next >> 1);

    // full,empty next 检测
    assign rempty_next = (rgray_next == wgray_rsync2);
    assign wfull_next =
        (wgray_next == {~rgray_wsync2[PtrWidth-1:PtrWidth-2],
                        rgray_wsync2[PtrWidth-3:0]});


    // 判断 push pop
    logic wpush,rpop;
    assign wpush = winc && !wfull;
    assign rpop = rinc && !rempty;


    // ptr next
    assign wbin_next = wbin + wpush;
    assign rbin_next = rbin + rpop;

    always @(posedge wclk or negedge wrst_n) begin
        if(!wrst_n) begin
            wbin <= '0;
            wfull <= 1'b0;
            wgray <= '0;
        end else begin
            wbin <= wbin_next;
            wfull <= wfull_next;
            wgray <= wgray_next;
        end
    end


    always @(posedge rclk or negedge rrst_n) begin
        if(!rrst_n) begin
            rbin <= '0;
            rempty <= 1'b1;
            rgray <= '0;
        end else begin
            rbin <= rbin_next;
            rempty <= rempty_next;
            rgray <= rgray_next;
        end
    end


    // 数据写入和读出
    logic [DATA_WIDTH-1:0] mem [DEPTH];

    always_ff @(posedge wclk ) begin
        if (wpush) begin
            mem[wbin[ADDR_WIDTH-1:0]] <= wdata;
        end
        else begin
            mem[wbin[ADDR_WIDTH-1:0]] <= mem[wbin[ADDR_WIDTH-1:0]];
        end

    end


    always_ff @( posedge rclk or negedge rrst_n ) begin
        if (! rrst_n) begin
            rdata <= '0;
        end else if (rpop) begin
            rdata <= mem[rbin[ADDR_WIDTH-1:0]];
        end
        else begin
            rdata <= rdata;
        end
    end

//  此版本不足 没有判断 width = 1的代码

endmodule
