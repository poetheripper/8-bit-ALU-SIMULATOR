`timescale 1ns / 1ps

module demux9bit_tb;

    reg sel;
    reg [8:0] d;
    wire [8:0] a;
    wire [8:0] b;

    demux9bit uut (
        .sel(sel),
        .d(d),
        .a(a),
        .b(b)
    );

    initial begin
        $display("Time\t sel \t d \t\t a \t\t b");
        $monitor("%0t\t %b \t %b \t %b \t %b", $time, sel, d, a, b);

        sel = 1'b0; d = 9'b000010101;
        #10;

        sel = 1'b1;
        #10;
        
        d = 9'b111000101;
        #10;

        sel = 1'b0;
        #10;

        $finish;
    end

endmodule 
