`timescale 1ns / 1ps

module mux9bit_tb;

    reg [8:0] a;
    reg [8:0] b;
    reg       sel;
    wire [8:0] out;

    mux9bit uut (
        .a(a),
        .b(b),
        .sel(sel),
        .out(out)
    );

    initial begin
        $display("Time\t sel \t a \t\t b \t\t out");
        $monitor("%0t\t %b \t %b \t %b \t %b", $time, sel, a, b, out);

        a = 9'b000010101; b = 9'b101100110; sel = 1'b0;
        #10;

        sel = 1'b1;
        #10;

        a = 9'b111000101;
        #10;

        sel = 1'b0;
        #10;

        $finish; 
    end

endmodule
