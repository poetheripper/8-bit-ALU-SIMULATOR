`timescale 1ns / 1ps
`include "u_reg.v"
`include "control_unit.v"
`include "CLA_9bit.v"
`include "demux9bit.v"
`include "mux9bit.v"
`include "d_flip_flop.v"

module ALU_Top (
    input wire clk,
    input wire reset,         
    input wire begin_op,      
    input wire [1:0] op,      // 00=ADD, 01=SUB, 10=MUL, 11=DIV
    input wire [7:0] inbus,   // Magistrala de intrare date
    output wire [7:0] outbus  // Magistrala de iesire date
);

    
    // Iesirile din Registrele de Shiftare
    wire [8:0] A_out;
    wire [7:0] Q_out;
    wire [7:0] Q_prim_out;
    wire [8:0] M_out;
    
	//contoare+ Q[-1]
    reg       Q_m1;       
    reg [2:0] cnt1;       
    reg [2:0] cnt2;       


    //Semnale Control Unit & Adder
    wire C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15, C16;
    wire [8:0] adder_in1, adder_in2, xor_input, adder_out;
    wire [8:0] mux1_out;
    wire [8:0] demux1_out1, demux1_out2, demux2_in, demux2_out1, demux2_out2;

    
    // Instantiere Control Unit & Adder
    control_unit cu_inst (
        .clk(clk), .Begin(begin_op), .Reset(reset),
        .cnt1(cnt1), .cnt2(cnt2), .M7(M_out[7]), .A8(A_out[8]), .A7(A_out[7]), .A6(A_out[6]),
        .Q_0(Q_out[0]), .Q_minus_1(Q_m1), .op(op),
        .C0(C0), .C1(C1), .C2(C2), .C3(C3), .C4(C4), .C5(C5), .C6(C6), .C7(C7),
        .C8(C8), .C9(C9), .C10(C10), .C11(C11), .C12(C12), .C13(C13), .C14(C14), .C15(C15), .C16(C16)
    );

    mux9bit mux1(.a(A_out), .b({1'b0, Q_out}), .sel(C15), .out(mux1_out));
    mux9bit mux2(.a(mux1_out), .b({8'b0, 1'b1}), .sel(C13), .out(adder_in1));
    mux9bit mux3(.a(M_out), .b({1'b0, Q_prim_out}), .sel(C16), .out(xor_input));

    assign adder_in2 = xor_input ^ {9{C3}};

    CLA_9bit adder_inst ( .X(adder_in1), .Y(adder_in2), .cin(C3), .Z(adder_out));

    demux9bit demux1(.d(adder_out), .sel(C13), .a(demux1_out1), .b(demux1_out2));
    demux9bit demux2(.d(demux1_out1), .sel(C15), .a(demux2_out1), .b(demux2_out2));

    
    // Logica de control a intrarilor pentru Shift Registers
    reg [8:0] A_d; 
    reg [7:0] Q_d;  
    reg [7:0] Q_prim_d; 
    reg [8:0] M_d; 
   
    reg A_sh_ld, A_l_r, A_sl_in, A_sr_in;
    reg Q_sh_ld, Q_l_r, Q_sl_in, Q_sr_in;
    reg Q_prim_sh_ld, Q_prim_l_r, Q_prim_sl_in, Q_prim_sr_in;
    reg M_sh_ld, M_l_r, M_sl_in, M_sr_in;


    always @(*) begin
    
        A_sh_ld = 1'b1;  A_d = A_out;       
        Q_sh_ld = 1'b1;  Q_d = Q_out;       
        Q_prim_sh_ld = 1'b1;  Q_prim_d = Q_prim_out; 
        M_sh_ld = 1'b1;  M_d = M_out;      

        if (!reset) begin
            // Reset asincron
            A_d = 9'b0; Q_d = 8'b0; Q_prim_d = 8'b0; M_d = 9'b0;
        end else begin
            
            //Logica Registrelor
            if (C0) begin
                A_d = 9'b0; // Initializeaza
		Q_prim_d = 8'b0;
		M_d = {inbus[7], inbus}; // load cu extensie de semn
	    end
    
	    if (C1) begin
		Q_d = inbus;
	    end

            if (C2) begin
		if (C13) begin
			Q_prim_d = demux1_out2[7:0]; // corectie Q' = Q' + 1
		end else if (C15 || C16) begin
			Q_d = demux2_out2[7:0]; // Q +- M / Q - Q'
		end else begin
			A_d = demux2_out1;
		end
	    end   

	    if (C4) begin
		A_sh_ld = 1'b0; A_l_r = 1'b1; A_sr_in = A_out[8]; 	
		Q_sh_ld = 1'b0; Q_l_r = 1'b1; Q_sr_in = A_out[0];
   	    end

	    if (C8) begin
			M_sh_ld = 1'b0; M_l_r = 1'b0; M_sl_in = 1'b0;	
			Q_sh_ld = 1'b0; Q_l_r = 1'b0; Q_sl_in = 1'b0;
			A_sh_ld = 1'b0; A_l_r = 1'b0; A_sl_in = Q_out[7];
	    end

            if (C9) begin
			A_sh_ld = 1'b0; A_l_r = 1'b0; A_sl_in = Q_out[7]; // A primeste din Q
                	Q_sh_ld = 1'b0; Q_l_r = 1'b0; Q_sl_in = C10;      // Q primeste bit cat
                	Q_prim_sh_ld= 1'b0; Q_prim_l_r = 1'b0; Q_prim_sl_in= C11;
	    end

	    if (C14) begin
			A_sh_ld = 1'b0; A_l_r = 1'b1; A_sr_in = 1'b0; // shiftare la dreapta cu k biti
	    end
	end
    end


    //Instantierea Registrelor Speciale

    u_reg #(.N(9)) reg_A (
        .clk(clk), .l_r(A_l_r), .sh_ld(A_sh_ld), .sr(A_sr_in), .sl(A_sl_in), .d(A_d), .q(A_out)
    );

    u_reg #(.N(8)) reg_Q (
        .clk(clk), .l_r(Q_l_r), .sh_ld(Q_sh_ld), .sr(Q_sr_in), .sl(Q_sl_in), .d(Q_d), .q(Q_out)
    );

    u_reg #(.N(8)) reg_Q_prim (
        .clk(clk), .l_r(Q_prim_l_r), .sh_ld(Q_prim_sh_ld), .sr(Q_prim_sr_in), .sl(Q_prim_sl_in), .d(Q_prim_d), .q(Q_prim_out)
    );

    u_reg #(.N(9)) reg_M (
        .clk(clk), .l_r(M_l_r), .sh_ld(M_sh_ld), .sr(M_sr_in), .sl(M_sl_in), .d(M_d), .q(M_out)
    );

    //Contoare si Q[-1] 
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            Q_m1 <= 1'b0;
            cnt1 <= 3'd0;
            cnt2 <= 3'd0;
        end else begin
            if (C0) Q_m1 <= 1'b0;
            else if (C4) Q_m1 <= Q_out[0];

            if (C0) cnt1 <= 3'd0;
            else if (C5 || C8) cnt1 <= cnt1 + 3'd1;
            else if (C14) cnt1 <= cnt1 - 3'd1;

            if (C0) cnt2 <= 3'd0;
            else if (C12) cnt2 <= cnt2 + 3'd1;
        end
    end

    //Iesire

    assign outbus = (C6) ? A_out[7:0] : 
                    (C7) ? Q_out[7:0] : 
                    8'bZZZZZZZZ;

endmodule 
