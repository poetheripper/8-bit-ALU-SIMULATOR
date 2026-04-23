`timescale 1ns / 1ps

module mux9bit_tb;

    // 1. Declare signals
    reg [8:0] a;
    reg [8:0] b;
    reg       sel;
    wire [8:0] out;

    // 2. Instantiate the Unit Under Test (UUT)
    // This connects to the module we designed earlier
    mux9bit uut (
        .a(a),
        .b(b),
        .sel(sel),
        .out(out)
    );

    // 3. Stimulus generation
    initial begin
        // Display a header in the console
        $display("Time\t sel \t a \t\t b \t\t out");
        $monitor("%0t\t %b \t %b \t %b \t %b", $time, sel, a, b, out);

        // Test Case 1: Select Input A
        a = 9'b000010101; b = 9'b101100110; sel = 1'b0;
        #10; // Wait 10 time units

        // Test Case 2: Select Input B
        sel = 1'b1;
        #10;

        // Test Case 3: Change A while sel is 1 (Output should stay as B)
        a = 9'b111000101;
        #10;

        // Test Case 4: Switch back to A (Output should now be the new A)
        sel = 1'b0;
        #10;

        $finish; // End the simulation
    end

endmodule