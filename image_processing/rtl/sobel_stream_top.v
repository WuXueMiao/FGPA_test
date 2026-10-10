module sobel_stream_top #(
    parameter IMG_WIDTH = 640,
    parameter X_WIDTH   = 11,
    parameter Y_WIDTH   = 11
)(
    input                   clk,
    input                   rst_n,

    input      [7:0]        pixel_in,
    input                   pixel_valid,
    input                   sof,
    input                   eol,

    input      [10:0]       threshold,

    output     [7:0]        edge_gray,
    output     [7:0]        edge_out,
    output                  edge_valid,
    output     [X_WIDTH-1:0] edge_x,
    output     [Y_WIDTH-1:0] edge_y
);

    wire [7:0] p00, p01, p02;
    wire [7:0] p10, p11, p12;
    wire [7:0] p20, p21, p22;

    wire window_valid;
    wire [X_WIDTH-1:0] center_x;
    wire [Y_WIDTH-1:0] center_y;

    // 像素流 → 3×3 窗口
    window_3x3 #(
        .IMG_WIDTH(IMG_WIDTH),
        .X_WIDTH(X_WIDTH),
        .Y_WIDTH(Y_WIDTH)
    ) u_window_3x3 (
        .clk(clk),
        .rst_n(rst_n),

        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),
        .sof(sof),
        .eol(eol),

        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .window_valid(window_valid),

        .center_x(center_x),
        .center_y(center_y)
    );

    // 3×3 窗口 → Sobel 边缘结果
    sobel_core u_sobel_core (
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),

        .threshold(threshold),
        .edge_gray(edge_gray),
        .edge_out(edge_out)
    );

    // edge_out 对应窗口中心坐标
    assign edge_valid = window_valid;
    assign edge_x = center_x;
    assign edge_y = center_y;

endmodule
