module subtractor8bit (
    input  [7:0] x, y,
    input        s, // 0 Add, 1 Subtract
    output [7:0] z,
    output       c_out
);
    wire [7:0] y_xor_s;
    wire [8:0] carry;

    // poarta exor cu 8 biti de s
    assign y_xor_s = y ^ {8{s}}; 
    
    
    assign carry[0] = s;  //primul carry in e s 
    assign c_out     = carry[8];

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin 
            fac fa (
                .x(x[i]),
                .y(y_xor_s[i]),
                .c_in(carry[i]),
                .c_out(carry[i+1]),
                .z(z[i])
            );
        end
    endgenerate
endmodule


module parallel_adder8bit (
    input [7:0] x,y,
    input c_in,
    output [7:0] z,
    output c_out
    
  );
  
wire [8:0] carry;
assign carry[0] = c_in;
assign c_out     = carry[8];

genvar i;
generate
        for (i = 0; i < 8; i = i + 1) begin 
            fac fa (
                .x(x[i]),
                .y(y[i]),
                .c_in(carry[i]),
                .c_out(carry[i+1]),
                .z(z[i])
            );
        end
    endgenerate
endmodule


module fac (
  input x,y,c_in,
  output c_out,z
  );
  
assign z = x^y^c_in;
assign c_out = x&y | x&c_in | y&c_in;

endmodule 