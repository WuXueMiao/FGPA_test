`timescale 1ns / 1ps

module tb_sobel_stream_top_v2;

    reg clk;
    reg rst_n;

    reg [7:0] pixel_in;
    reg pixel_valid;
    reg sof;
    reg eol;
    reg [10:0] threshold;

    wire [7:0] edge_out;
    wire edge_valid;
    wire [10:0] edge_x;
    wire [10:0] edge_y;

    integer result_count;
    integer edge_count;
    integer nonedge_count;

    sobel_stream_top_v2 #(
        .IMG_WIDTH(5),
        .X_WIDTH(11),
        .Y_WIDTH(11)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),

        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),
        .sof(sof),
        .eol(eol),

        .threshold(threshold),

        .edge_out(edge_out),
        .edge_valid(edge_valid),
        .edge_x(edge_x),
        .edge_y(edge_y)
    );

    always #5 clk = ~clk;

    task send_pixel;
        input [7:0] value;
        input       is_sof;
        input       is_eol;
        begin
            pixel_in = value;
            pixel_valid = 1;
            sof = is_sof;
            eol = is_eol;

            @(posedge clk);
            #1;

            if (edge_valid) begin
                result_count = result_count + 1;

                if (edge_out == 8'd255)
                    edge_count = edge_count + 1;
                else
                    nonedge_count = nonedge_count + 1;

                $display(
                    "结果 #%0d，坐标=(%0d,%0d)，edge_out=%0d",
                    result_count, edge_x, edge_y, edge_out
                );
            end
        end
    endtask

    task send_gap;
        begin
            pixel_valid = 0;
            sof = 0;
            eol = 0;

            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        pixel_in = 0;
        pixel_valid = 0;
        sof = 0;
        eol = 0;

        threshold = 11'd200;
        result_count = 0;
        edge_count = 0;
        nonedge_count = 0;

        #12;
        rst_n = 1;

        // 5×5 测试图：每行均为 0 0 255 255 255
        // 左黑右白；窗口滑过交界时应检测到竖直边缘。

        // 第 0 行
        send_pixel(0,   1, 0);
        send_gap;
        send_pixel(0,   0, 0);
        send_pixel(255, 0, 0);
        send_pixel(255, 0, 0);
        send_pixel(255, 0, 1);

        // 第 1 行
        send_pixel(0,   0, 0);
        send_pixel(0,   0, 0);
        send_pixel(255, 0, 0);
        send_pixel(255, 0, 0);
        send_pixel(255, 0, 1);

        // 第 2 行
        send_pixel(0,   0, 0);
        send_pixel(0,   0, 0);
        send_pixel(255, 0, 0);
        send_pixel(255, 0, 0);
        send_pixel(255, 0, 1);

        // 第 3 行
        send_pixel(0,   0, 0);
        send_pixel(0,   0, 0);
        send_pixel(255, 0, 0);
        send_pixel(255, 0, 0);
        send_pixel(255, 0, 1);

        // 第 4 行
        send_pixel(0,   0, 0);
        send_pixel(0,   0, 0);
        send_pixel(255, 0, 0);
        send_pixel(255, 0, 0);
        send_pixel(255, 0, 1);

        // 第二帧：全灰图，验证 sof 能重新开始一帧
        // 此帧的 9 个有效输出都应为非边缘

        // 第 0 行
        send_pixel(100, 1, 0);
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 1);

        // 第 1 行
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 1);

        // 第 2 行
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 1);

        // 第 3 行
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 1);

        // 第 4 行
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 0);
        send_pixel(100, 0, 1);

        pixel_valid = 0;
        sof = 0;
        eol = 0;
        #10;

        $display("--------------------------------");
        $display("有效结果总数：%0d，预期为 18", result_count);
        $display("检测到边缘：%0d，预期为 6", edge_count);
        $display("非边缘区域：%0d，预期为 12", nonedge_count);
        $display("--------------------------------");

        $finish;
    end

endmodule