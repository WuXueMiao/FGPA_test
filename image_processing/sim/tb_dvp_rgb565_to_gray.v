`timescale 1ns/1ps

module tb_dvp_rgb565_to_gray;

    reg        pclk;
    reg        rst_n;
    reg        vsync;
    reg        href;
    reg [7:0]  data_in;

    wire [7:0] gray_pixel;
    wire       pixel_valid;
    wire       sof;
    wire       eol;

    integer pixel_count;

    dvp_rgb565_to_gray uut (
        .pclk        (pclk),
        .rst_n       (rst_n),
        .vsync       (vsync),
        .href        (href),
        .data_in     (data_in),
        .gray_pixel  (gray_pixel),
        .pixel_valid (pixel_valid),
        .sof         (sof),
        .eol         (eol)
    );

    always #5 pclk = ~pclk;

    // 发送一个 RGB565 像素：高字节、低字节
    task send_pixel;
        input [15:0] rgb565;
        begin
            // 进入任务时立刻给高字节，避免相邻像素之间出现空拍
            data_in = rgb565[15:8];

            @(negedge pclk);
            data_in = rgb565[7:0];

            @(negedge pclk);
        end
    endtask

    always @(posedge pclk) begin
        if (pixel_valid) begin
            pixel_count = pixel_count + 1;
            $display("像素 #%0d: gray=%0d, sof=%0d, eol=%0d",
                     pixel_count, gray_pixel, sof, eol);
        end
    end

    initial begin
        pclk        = 0;
        rst_n       = 0;
        vsync       = 0;
        href        = 0;
        data_in     = 0;
        pixel_count = 0;

        #20;
        rst_n = 1;

        // 新帧开始：本配置中 VSYNC=1 表示有效帧
        @(negedge pclk);
        vsync = 1;
        href  = 1;

        // 一行五个 RGB565 像素
        send_pixel(16'h0000); // 黑：预期灰度 0
        send_pixel(16'hf800); // 红：预期灰度约 63
        send_pixel(16'h07e0); // 绿：预期灰度约 126
        send_pixel(16'h001f); // 蓝：预期灰度约 63
        send_pixel(16'hffff); // 白：预期灰度约 252

        // send_pixel 返回时已经位于 negedge，立刻结束本行
        href = 0;

        @(negedge pclk);
        vsync = 0;

        #30;

        $display("--------------------------------");
        $display("有效像素总数：%0d，预期为 5", pixel_count);
        $display("--------------------------------");

        $finish;
    end

endmodule