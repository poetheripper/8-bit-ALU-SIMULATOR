module JK_flip_flop (
    input j,
    input k,
    input clk,
    input rst,
    output reg q,      // Must be 'reg' because it's assigned in an always block
    output q_bar       // This is the common name for q_prim
);

    // This triggers ONLY when the clock goes from 0 to 1
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            q <= 1'b0; // Force to 0 when reset is active
        end else begin
            case ({j, k})
                2'b00 : q <= q;
                2'b01 : q <= 1'b0;
                2'b10 : q <= 1'b1;
                2'b11 : q <= ~q;
            endcase
        end
    end

    // q_bar is always the inverse of q
    assign q_bar = ~q;

endmodule