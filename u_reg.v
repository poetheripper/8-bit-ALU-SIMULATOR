module u_shift_reg #(parameter N = 8)(
   input clk,
   input l_r, //0 - pentru dreapta, 1 - pentru stanga
   input sh_ld,
   input sr,
   input sl, 
   input [N-1:0] d,
   output wire [N-1:0] q
);

   wire [N-1:0] next_q;
  
   genvar i;
   generate 
	for(i = 0; i < N; i = i + 1) begin : stage
	    wire right_in;
	    wire left_in;

	    // pentru poarta R 
	    if(i == 0)
		assign right_in = sl;
	    else
		assign right_in = q[i-1];

	    // pentru poarta L
	    if(i == N - 1)
		assign left_in = sr;
	    else
		assign left_in = q[i+1];

	    assign next_q[i] = (~l_r & ~sh_ld & right_in) | (l_r & ~sh_ld & left_in)| ( sh_ld & d[i]);

	    
	    d_flip_flop dff_inst(
		.clk(clk),
		.d(next_q[i]),
		.q(q[i])
	    );
	end
   endgenerate 

endmodule 
	
	    