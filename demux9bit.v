module demux(
   input sel,
   input d,
   output a, b
);
   assign a = d & ~sel;
   assign b = d & sel;
endmodule 

module demux9bit(
   input [8:0]d,
   input sel,
   output [8:0]a,
   output [8:0]b
);

   genvar i;
   generate 
	for(i = 0; i < 9; i = i + 1)begin : demux_loop
		demux dex(
			.sel(sel),
			.d(d[i]),
			.a(a[i]),
			.b(b[i])
		);
	end
   endgenerate
endmodule 