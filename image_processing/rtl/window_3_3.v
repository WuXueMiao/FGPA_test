//window_3x3_v2相比于v1的核心变化：
//用 eol 判断换行，不再依赖固定图像宽度去数列；
//用 sof 判断新帧开始，避免两帧之间的数据混在一起；
//输出 center_x / center_y，明确 Sobel 输出属于原图的中心像素 (x−1, y−1)

module window_3x3_v2 #(
    parameter IMG_WIDTH = 640,  // 实际图像每行最大像素数；当前先按 640 设计
    parameter X_WIDTH   = 11,   // 640 需要 10 位，留 11 位更方便
    parameter Y_WIDTH   = 11
)(
    input                   clk,
    input                   rst_n,

    input      [7:0]        pixel_in,
    input                   pixel_valid,
    input                   sof,        // 当前有效像素是本帧第一个像素
    input                   eol,        // 当前有效像素是本行最后一个像素

    output reg [7:0]        p00, p01, p02,
    output reg [7:0]        p10, p11, p12,
    output reg [7:0]        p20, p21, p22,
    output reg              window_valid,

    // 方便后续调试和显示对齐：
    // 当前窗口结果属于原图的哪个中心坐标
    output reg [X_WIDTH-1:0] center_x,
    output reg [Y_WIDTH-1:0] center_y
);

    // 两条历史行：分别保存前一行、前两行
    reg [7:0] line1 [0:IMG_WIDTH-1];
    reg [7:0] line2 [0:IMG_WIDTH-1];

    // 每一行最近的两个像素
    reg [7:0] top_left, top_mid;
    reg [7:0] mid_left, mid_mid;
    reg [7:0] bot_left, bot_mid;

    // 当前正在接收的原图像素坐标
    reg [X_WIDTH-1:0] x_count;
    reg [Y_WIDTH-1:0] y_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_count <= 0;
            y_count <= 0;

            p00 <= 0; p01 <= 0; p02 <= 0;
            p10 <= 0; p11 <= 0; p12 <= 0;
            p20 <= 0; p21 <= 0; p22 <= 0;

            top_left <= 0; top_mid <= 0;
            mid_left <= 0; mid_mid <= 0;
            bot_left <= 0; bot_mid <= 0;

            window_valid <= 0;
            center_x <= 0;
            center_y <= 0;
        end
        else if (pixel_valid) begin

            // sof 与本帧的第一个有效像素绑定
            // 不必清空整块 RAM：前两行本来就不输出有效窗口
            if (sof) begin
                x_count <= 0;
                y_count <= 0;

                line2[0] <= line1[0];
                line1[0] <= pixel_in;

                top_left <= 0;
                top_mid  <= line2[0];
                mid_left <= 0;
                mid_mid  <= line1[0];
                bot_left <= 0;
                bot_mid  <= pixel_in;

                p00 <= 0; p01 <= 0; p02 <= 0;
                p10 <= 0; p11 <= 0; p12 <= 0;
                p20 <= 0; p21 <= 0; p22 <= 0;

                window_valid <= 0;
                center_x <= 0;
                center_y <= 0;

                // 正常图像宽度不会只有一个像素；
                // 此处仍兼容 sof 和 eol 同时出现的情况
                if (eol) begin
                    x_count <= 0;
                    y_count <= 1;
                end
                else begin
                    x_count <= 1;
                    y_count <= 0;
                end
            end
            else begin
                // 当前列：读取旧的前两行，同时更新两条行缓存
                line2[x_count] <= line1[x_count];
                line1[x_count] <= pixel_in;

                // 每一行第一个像素：横向历史重新开始
                if (x_count == 0) begin
                    top_left <= 0;
                    top_mid  <= line2[x_count];

                    mid_left <= 0;
                    mid_mid  <= line1[x_count];

                    bot_left <= 0;
                    bot_mid  <= pixel_in;

                    window_valid <= 0;
                    center_x <= 0;
                    center_y <= 0;
                end
                else begin
                    // 横向滑动，构造三行各连续三个像素
                    top_left <= top_mid;
                    top_mid  <= line2[x_count];

                    mid_left <= mid_mid;
                    mid_mid  <= line1[x_count];

                    bot_left <= bot_mid;
                    bot_mid  <= pixel_in;

                    // 3×3 窗口
                    p00 <= top_left;
                    p01 <= top_mid;
                    p02 <= line2[x_count];

                    p10 <= mid_left;
                    p11 <= mid_mid;
                    p12 <= line1[x_count];

                    p20 <= bot_left;
                    p21 <= bot_mid;
                    p22 <= pixel_in;

                    // 当前输入为 I(x,y)，结果属于中心 I(x-1,y-1)
                    if ((x_count >= 2) && (y_count >= 2)) begin
                        window_valid <= 1;
                        center_x <= x_count - 1'b1;
                        center_y <= y_count - 1'b1;
                    end
                    else begin
                        window_valid <= 0;
                        center_x <= 0;
                        center_y <= 0;
                    end
                end

                // eol 决定换行；不再依赖“每行恰好 5 个像素”
                if (eol) begin
                    x_count <= 0;
                    y_count <= y_count + 1'b1;
                end
                else begin
                    x_count <= x_count + 1'b1;
                end
            end
        end
        else begin
            // 消隐/空拍不移动窗口、行缓存或坐标
            window_valid <= 0;
        end
    end

endmodule