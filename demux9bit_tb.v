`timescale 1ns / 1ps

module demux9bit_tb;

    // 1. Declare signals
    reg sel;
    reg [8:0] d;
    wire [8:0] a;
    wire [8:0] b;

    // 2. Instantiate the Unit Under Test (UUT)
    // This connects to the module we designed earlier
    demux9bit uut (
        .sel(sel),
        .d(d),
        .a(a),
        .b(b)
    );

    // 3. Stimulus generation
    initial begin
        // Display a header in the console
        $display("Time\t sel \t d \t\t a \t\t b");
        $monitor("%0t\t %b \t %b \t %b \t %b", $time, sel, d, a, b);

        // Test Case 1: Select Input A
        sel = 1'b0; d = 9'b000010101;
        #10; // Wait 10 time units

        // Test Case 2: Select Input B
        sel = 1'b1;
        #10;

        // Test Case 3: Change A while sel is 1 (Output should stay as B)
        d = 9'b111000101;
        #10;

        // Test Case 4: Switch back to A (Output should now be the new A)
        sel = 1'b0;
        #10;

        $finish; // End the simulation
    end

endmodule 