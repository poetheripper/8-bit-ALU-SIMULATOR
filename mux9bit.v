module mux(
   input a, b, sel,
   output out
);

   assign out = (a & ~sel) || (b & sel);
endmodule 

module mux9bit(
   input [8:0]a,
   input [8:0]b,
   input sel,
   output [8:0]out
);

   genvar i;
   generate
	for(i = 0; i < 9; i = i + 1)begin : mux_loop
		mux m(
			.a(a[i]),
			.b(b[i]),
			.sel(sel),
			.out(out[i])		
		);
	end
   endgenerate
endmodule 
		