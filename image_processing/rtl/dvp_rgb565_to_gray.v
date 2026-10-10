`timescale 1ns/1ps

// OV5640 DVP RGB565 -> 8-bit Gray
module dvp_rgb565_to_gray (
    input             pclk,
    input             rst_n,

    input             vsync,
    input             href,
    input      [7:0]  data_in,

    output reg [7:0]  gray_pixel,
    output reg        pixel_valid,
    output reg        sof,
    output reg        eol
);

    // RGB565 的第一个字节暂存
    reg [7:0] byte_high;
    reg       byte_phase;       // 0：等待第一个字节；1：等待第二个字节

    // 延迟一个 PCLK 输出，才能正确判断一行最后一个像素
    reg [7:0] pending_gray;
    reg       pending_valid;
    reg       pending_sof;

    // 用于在新一帧的首像素产生 sof
    reg vsync_d;
    reg frame_pending;

    reg [7:0] r8;
    reg [7:0] g8;
    reg [7:0] b8;

    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            byte_high    <= 8'd0;
            byte_phase   <= 1'b0;

            pending_gray <= 8'd0;
            pending_valid<= 1'b0;
            pending_sof  <= 1'b0;

            gray_pixel   <= 8'd0;
            pixel_valid  <= 1'b0;
            sof          <= 1'b0;
            eol          <= 1'b0;

            vsync_d      <= 1'b0;
            frame_pending<= 1'b0;
        end
        else begin
            // 默认：无输出
            pixel_valid <= 1'b0;
            sof         <= 1'b0;
            eol         <= 1'b0;

            // VSYNC 上升沿标记新帧；数据接收仅由 HREF 门控。
            vsync_d <= vsync;
            if (vsync && !vsync_d)
                frame_pending <= 1'b1;

            // 输出上一个已经拼好的像素
            if (pending_valid) begin
                gray_pixel  <= pending_gray;
                pixel_valid <= 1'b1;
                sof         <= pending_sof;

                // 上一个像素有效、当前 HREF 已无效：说明它是本行最后一个像素
                eol         <= !href;

                pending_valid <= 1'b0;
                pending_sof   <= 1'b0;
            end

            // HREF=1 时，DVP 数据有效
            if (href) begin
                if (!byte_phase) begin
                    // RGB565 的第一个字节：R[4:0] + G[5:3]
                    byte_high  <= data_in;
                    byte_phase <= 1'b1;
                end
                else begin
                    // 第二个字节：G[2:0] + B[4:0]
                    // 扩展为 8 位 RGB
                    r8 = {byte_high[7:3], 3'b000};
                    g8 = {byte_high[2:0], data_in[7:5], 2'b00};
                    b8 = {data_in[4:0], 3'b000};

                    // 灰度近似：0.25R + 0.5G + 0.25B
                    // 只使用移位和加法，适合 FPGA
                    pending_gray  <= (r8 >> 2) + (g8 >> 1) + (b8 >> 2);
                    pending_valid <= 1'b1;
                    pending_sof   <= frame_pending;

                    frame_pending <= 1'b0;
                    byte_phase    <= 1'b0;
                end
            end
            else begin
                // 行间空白：重新等待下一个像素的第一个字节
                byte_phase <= 1'b0;
            end
        end
    end

endmodule
