module sobel_core ( //输入一个3*3的灰度窗口，2^8的范围0是黑色，255是白色
    input  [7:0] p00, p01, p02,
    input  [7:0] p10, p11, p12,
    input  [7:0] p20, p21, p22,

    input  [10:0] threshold,  // 可调阈值
    output reg [7:0] edge_out // 255: 白色边缘；0: 黑色背景
);

    // Gx、Gy 可能为负数，因此必须定义为 signed
    reg signed [10:0] gx;
    reg signed [10:0] gy;

    // 绝对值和最终梯度幅值一定非负
    reg [10:0] abs_gx;
    reg [10:0] abs_gy;
    reg [11:0] magnitude;

    always @(*) begin
        // 横向梯度：检测“左暗右亮”或“左亮右暗”的竖直边缘
        gx =  $signed({1'b0, p02})
            + ($signed({1'b0, p12}) <<< 1)
            +  $signed({1'b0, p22})
            -  $signed({1'b0, p00})
            - ($signed({1'b0, p10}) <<< 1)
            -  $signed({1'b0, p20});

        // 纵向梯度：检测“上暗下亮”或“上亮下暗”的水平边缘
        gy =  $signed({1'b0, p20})
            + ($signed({1'b0, p21}) <<< 1)
            +  $signed({1'b0, p22})
            -  $signed({1'b0, p00})
            - ($signed({1'b0, p01}) <<< 1)
            -  $signed({1'b0, p02});

        // 计算绝对值
        abs_gx = (gx < 0) ? -gx : gx;
        abs_gy = (gy < 0) ? -gy : gy;

        // 用 |Gx| + |Gy| 近似梯度幅值，避免硬件开方
        magnitude = abs_gx + abs_gy;

        // 二值化输出
        if (magnitude > threshold)
            edge_out = 8'd255; // 白色：检测到边缘
        else
            edge_out = 8'd0;   // 黑色：没有边缘
    end

endmodule