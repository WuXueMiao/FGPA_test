`timescale 1ns/1ps

module tb_camera_sobel_top;

    reg        pclk;
    reg        rst_n;
    reg        vsync;
    reg        href;
    reg [7:0]  cmos_data;
    reg [10:0] threshold;

    wire [7:0]  edge_gray;
    wire [7:0]  edge_out;
    wire        edge_valid;
    wire [10:0] edge_x;
    wire [10:0] edge_y;

    integer result_count;
    integer edge_count;

    camera_sobel_top #(
        .IMG_WIDTH(5),
        .X_WIDTH  (11),
        .Y_WIDTH  (11)
    ) uut (
        .pclk      (pclk),
        .rst_n     (rst_n),
        .vsync     (vsync),
        .href      (href),
        .cmos_data (cmos_data),
        .threshold (threshold),

        .edge_gray  (edge_gray),
        .edge_out   (edge_out),
        .edge_valid (edge_valid),
        .edge_x     (edge_x),
        .edge_y     (edge_y)
    );

    always #5 pclk = ~pclk;

    // 一个 RGB565 像素分两个 PCLK 传输
    task send_pixel;
        input [15:0] rgb565;
        begin
            cmos_data = rgb565[15:8];
            @(negedge pclk);
            cmos_data = rgb565[7:0];
            @(negedge pclk);
        end
    endtask

    // 左黑右白的一行：应在中间竖直边缘产生响应
    task send_edge_line;
        begin
            href = 1;
            send_pixel(16'h0000);
            send_pixel(16'h0000);
            send_pixel(16'hffff);
            send_pixel(16'hffff);
            send_pixel(16'hffff);

            href = 0;
            @(negedge pclk);
        end
    endtask

    // 均匀黑色的一行：不应有边缘
    task send_black_line;
        begin
            href = 1;
            send_pixel(16'h0000);
            send_pixel(16'h0000);
            send_pixel(16'h0000);
            send_pixel(16'h0000);
            send_pixel(16'h0000);

            href = 0;
            @(negedge pclk);
        end
    endtask

    always @(posedge pclk) begin
        #1;
        if (edge_valid) begin
            if (result_count >= 18 ||
                edge_x !== ((result_count % 3) + 1) ||
                edge_y !== (((result_count % 9) / 3) + 1) ||
                edge_out !== ((result_count < 9 && result_count % 3 < 2) ? 8'd255 : 8'd0))
                $fatal(1, "Camera Sobel pixel/coordinate mismatch at %0d", result_count);
            result_count = result_count + 1;

            if (edge_out != 0)
                edge_count = edge_count + 1;

            $display("结果 #%0d，坐标=(%0d,%0d)，edge_out=%0d",
                     result_count, edge_x, edge_y, edge_out);
        end
    end

    initial begin
        pclk         = 0;
        rst_n        = 0;
        vsync        = 0;
        href         = 0;
        cmos_data    = 0;
        threshold    = 11'd200;
        result_count = 0;
        edge_count   = 0;

        #20;
        rst_n = 1;

        // 第 1 帧：左黑右白，共 5×5，预期 9 个窗口、6 个边缘
        @(negedge pclk);
        vsync = 1;

        send_edge_line;
        send_edge_line;
        send_edge_line;
        send_edge_line;
        send_edge_line;

        // 帧间空白
        @(negedge pclk);
        vsync = 0;
        href  = 0;

        // 第 2 帧：均匀黑色，共 5×5，预期 9 个窗口、0 个边缘
        @(negedge pclk);
        vsync = 1;

        send_black_line;
        send_black_line;
        send_black_line;
        send_black_line;
        send_black_line;

        @(negedge pclk);
        vsync = 0;
        href  = 0;

        #100;

        $display("--------------------------------");
        $display("有效结果总数：%0d，预期为 18", result_count);
        $display("检测到边缘：%0d，预期为 6", edge_count);
        $display("非边缘区域：%0d，预期为 12", result_count - edge_count);
        $display("--------------------------------");

        if (result_count != 18 || edge_count != 6)
            $fatal(1, "Camera Sobel output count mismatch");
        $display("PASS tb_camera_sobel_top");
        $finish;
    end

endmodule
