`timescale 1ns/1ps
module u_shift_reg_tb;
    parameter N = 8;
    reg clk, l_r, sh_ld, sr, sl;
    reg [N-1:0] d;
    wire[N-1:0] q;

    u_shift_reg #(.N(N)) uut (
        .clk  (clk),
        .l_r  (l_r),
        .sh_ld(sh_ld),
        .sr   (sr),
        .sl   (sl),
        .d    (d),
        .q    (q)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task apply_and_check;
        input [N-1:0] expected;
        input [63:0]  test_num;
        begin
            @(posedge clk); #1;
            if (q === expected)
                $display("TEST %0d PASSED | Q = %08b", test_num, q);
            else
                $display("TEST %0d FAILED | Q = %08b, expected %08b", test_num, q, expected);
        end
    endtask

    initial begin
        l_r   = 0;
        sh_ld = 0;
        sr    = 0;
        sl    = 0;
        d     = 8'b0;
        #12;



        $display("\n=== TEST 1: Parallel Load (10101010) ===");
        sh_ld = 1; l_r = 0; d = 8'b10101010;
        apply_and_check(8'b10101010, 1);

        $display("\n=== TEST 2: Parallel Load (11001100) ===");
        d = 8'b11001100;
        apply_and_check(8'b11001100, 2);

        $display("\n=== TEST 3: Shift Right (Towards MSB), SR=1 ===");
        sh_ld = 0; l_r = 1; sr = 1;
        apply_and_check(8'b11100110, 3);

        $display("\n=== TEST 4: Shift Right (Towards MSB), SR=0 ===");
        sr = 0;
        apply_and_check(8'b01110011, 4);

        $display("\n=== TEST 5: Shift Right (Towards MSB), SR=0 ===");
        apply_and_check(8'b00111001, 5);


        $display("\n=== TEST 6: Shift Left (Towards LSB), SL=1 ===");
        sh_ld = 0; l_r = 0; sl = 1;
        apply_and_check(8'b01110011, 6);

        $display("\n=== TEST 7: Shift Left (Towards LSB), SL=0 ===");
        sl = 0;
        apply_and_check(8'b11100110, 7);

        $display("\n=== TEST 8: Shift Left (Towards LSB), SL=0 ===");
        apply_and_check(8'b11001100, 8);




        $display("\n=== TEST 9: Load 11110000 ===");
        sh_ld = 1; l_r = 0; d = 8'b11110000;
        apply_and_check(8'b11110000, 9);

        $display("\n=== TEST 10-12: Shift Right x3 (Towards MSB), SR=0 ===");
        sh_ld = 0; l_r = 1; sr = 0;
        apply_and_check(8'b01111000, 10);
        
        apply_and_check(8'b00111100, 11);
        
        apply_and_check(8'b00011110, 12);

        $display("\n=== All tests complete ===\n");
        $finish;
    end
endmodule 