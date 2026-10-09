`timescale 1ns/1ps

// OV5640 DVP(RGB565) → Gray → Sobel
module camera_sobel_top #(
    parameter IMG_WIDTH = 1280,
    parameter X_WIDTH   = 11,
    parameter Y_WIDTH   = 11
)(
    // OV5640 DVP 接口
    input                   pclk,
    input                   rst_n,
    input                   vsync,
    input                   href,
    input      [7:0]        cmos_data,

    // Sobel 阈值
    input      [10:0]       threshold,

    // 边缘检测结果
    output     [7:0]        edge_out,
    output                  edge_valid,
    output     [X_WIDTH-1:0] edge_x,
    output     [Y_WIDTH-1:0] edge_y
);

    wire [7:0] gray_pixel;
    wire       pixel_valid;
    wire       sof;
    wire       eol;

    // DVP 的两个 RGB565 字节 → 一个灰度像素
    dvp_rgb565_to_gray u_dvp_rgb565_to_gray (
        .pclk        (pclk),
        .rst_n       (rst_n),
        .vsync       (vsync),
        .href        (href),
        .data_in     (cmos_data),

        .gray_pixel  (gray_pixel),
        .pixel_valid (pixel_valid),
        .sof         (sof),
        .eol         (eol)
    );

    // 灰度像素流 → 3×3 滑窗 → Sobel 边缘
    sobel_stream_top #(
        .IMG_WIDTH (IMG_WIDTH),
        .X_WIDTH   (X_WIDTH),
        .Y_WIDTH   (Y_WIDTH)
    ) u_sobel_stream_top (
        .clk         (pclk),
        .rst_n       (rst_n),

        .pixel_in    (gray_pixel),
        .pixel_valid (pixel_valid),
        .sof         (sof),
        .eol         (eol),

        .threshold   (threshold),

        .edge_out    (edge_out),
        .edge_valid  (edge_valid),
        .edge_x      (edge_x),
        .edge_y      (edge_y)
    );

endmodule
