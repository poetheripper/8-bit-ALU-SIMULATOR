`timescale 1ns/1ps

module Substracter_adder_tb();

    // 1. Declare signals
    reg  [7:0] x_in, y_in;
    reg        s_ctrl;
    wire [7:0] z_out;
    wire       cout_out;

    // 2. Instantiate the Unit Under Test (UUT)
    subtractor8bit uut (
        .x(x_in),
        .y(y_in),
        .s(s_ctrl),
        .z(z_out),
        .c_out(cout_out)
    );

    // 3. Test Procedure
    initial begin
        // Monitor the console
        $display("Mode | X   | Y   | Result | Cout");
        $display("--------------------------------");
        $monitor("s=%b  | %d  | %d  | %d     | %b", s_ctrl, x_in, y_in, z_out, cout_out);

        // --- TEST CASE 1: Addition (s=0) ---
        s_ctrl = 0; x_in = 8'd25; y_in = 8'd10; #10; // Result should be 35
        x_in = 8'd128; y_in = 8'd128; #10;           // Result should be 0, cout=1 (Overflow)

        // --- TEST CASE 2: Subtraction (s=1) ---
        s_ctrl = 1; x_in = 8'd50; y_in = 8'd20; #10; // Result should be 30
        x_in = 8'd10; y_in = 8'd15; #10;             // Result should be 251 (negative in 2's complement)

        $display("--------------------------------");
        $display("Simulation Finished");
        $stop; // Pauses simulation in ModelSim
    end

endmodule