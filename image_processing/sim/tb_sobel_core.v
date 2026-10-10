`timescale 1ns/1ps

module tb_sobel_core;
    reg [7:0] p00, p01, p02;
    reg [7:0] p10, p11, p12;
    reg [7:0] p20, p21, p22;
    reg [10:0] threshold;
    wire [7:0] edge_gray;
    wire [7:0] edge_out;

    sobel_core uut (
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .threshold(threshold),
        .edge_gray(edge_gray),
        .edge_out(edge_out)
    );

    task check_result;
        input [7:0] expected_gray;
        input [7:0] expected_binary;
        begin
            #1;
            if (edge_gray !== expected_gray || edge_out !== expected_binary)
                $fatal(1, "Expected gray=%0d binary=%0d, got gray=%0d binary=%0d",
                       expected_gray, expected_binary, edge_gray, edge_out);
            $display("gray=%0d, binary=%0d", edge_gray, edge_out);
        end
    endtask

    initial begin
        p00 = 0; p01 = 0; p02 = 0;
        p10 = 0; p11 = 0; p12 = 0;
        p20 = 0; p21 = 0; p22 = 0;
        threshold = 11'd50;
        check_result(8'd0, 8'd0);

        // 垂直灰阶变化：Gx=20+2*20+20=80，未发生 8 位饱和。
        p02 = 20; p12 = 20; p22 = 20;
        check_result(8'd80, 8'd255);

        // Gx=400，灰度梯度输出应饱和为 255；阈值仍按完整幅值 400 比较。
        p02 = 100; p12 = 100; p22 = 100;
        threshold = 11'd500;
        check_result(8'd255, 8'd0);

        $display("PASS tb_sobel_core");
        $finish;
    end
endmodule
