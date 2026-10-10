`timescale 1ns/1ps

module tb_quad_full_frame;
    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg cam_rst_n = 1'b0;
    reg cam_pixel_valid = 1'b0;
    reg cam_sof = 1'b0;
    reg cam_eol = 1'b0;
    reg [7:0] cam_gray = 8'd0;
    reg edge_valid = 1'b0;
    reg [7:0] edge_data = 8'd0;
    reg [10:0] edge_x = 11'd0;
    reg [10:0] edge_y = 11'd0;

    reg disp_rst_n = 1'b0;
    reg disp_valid = 1'b0;
    reg [11:0] disp_x = 12'd0;
    reg [11:0] disp_y = 12'd0;
    wire [23:0] rgb_out;

    integer x;
    integer y;

    quad_full_frame #(.WIDTH(8), .HEIGHT(8)) dut (
        .cam_clk(clk),
        .cam_rst_n(cam_rst_n),
        .cam_pixel_valid(cam_pixel_valid),
        .cam_sof(cam_sof),
        .cam_eol(cam_eol),
        .cam_gray(cam_gray),
        .edge_valid(edge_valid),
        .edge_data(edge_data),
        .edge_x(edge_x),
        .edge_y(edge_y),
        .disp_clk(clk),
        .disp_rst_n(disp_rst_n),
        .disp_valid(disp_valid),
        .disp_x(disp_x),
        .disp_y(disp_y),
        .rgb_out(rgb_out)
    );

    initial begin
        repeat (3) @(negedge clk);
        cam_rst_n = 1'b1;
        disp_rst_n = 1'b1;

        // Send an 8x8 grayscale frame. Provide binary Sobel samples
        // at center coordinates (1,1), (5,1), (1,5), and (5,5).
        for (y = 0; y < 8; y = y + 1) begin
            for (x = 0; x < 8; x = x + 1) begin
                @(negedge clk);
                cam_pixel_valid = 1'b1;
                cam_sof = (x == 0 && y == 0);
                cam_eol = (x == 7);
                cam_gray = 8'h3c;
                edge_valid = ((x[1:0] == 1) && (y[1:0] == 1) && x < 7 && y < 7);
                edge_data = 8'hff;
                edge_x = x;
                edge_y = y;
            end
        end

        @(negedge clk);
        cam_pixel_valid = 1'b0;
        cam_sof = 1'b0;
        cam_eol = 1'b0;
        edge_valid = 1'b0;
        repeat (2) @(posedge clk);
        #1;

        if (dut.edge_mem[0] !== 8'hff || dut.edge_mem[1] !== 8'hff ||
            dut.edge_mem[2] !== 8'hff || dut.edge_mem[3] !== 8'hff) begin
            $fatal(1, "FAIL: edge samples were not written to all four cache entries");
        end

        // Display coordinate (4,4) is the first pixel of the bottom-right panel.
        @(negedge clk);
        disp_valid = 1'b1;
        disp_x = 12'd4;
        disp_y = 12'd4;
        @(posedge clk);
        #1;
        if (rgb_out !== 24'hffffff) begin
            $fatal(1, "FAIL: bottom-right panel RGB=%h, expected ffffff", rgb_out);
        end

        $display("PASS tb_quad_full_frame: Sobel white pixel reached bottom-right panel");
        $finish;
    end
endmodule
