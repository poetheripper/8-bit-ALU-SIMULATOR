`timescale 1ns / 1ps

module ALU_Top (
    input wire clk,
    input wire reset,         // Asincron, activ in LOW (0 = reset)
    input wire begin_op,      // Impuls de start
    input wire [1:0] op,      // 00=ADD, 01=SUB, 10=MUL, 11=DIV
    input wire [7:0] inbus,   // Magistrala de intrare date
    output wire [7:0] outbus  // Magistrala de iesire date
);

    // ==========================================
    // 1. Iesirile din Registrele de Shiftare
    // ==========================================
    wire [8:0] A_out;
    wire [7:0] Q_out;
    wire [7:0] Q_prime_out;
    wire [8:0] M_out;
    
    // Semnale auxiliare (flip-flop simplu pt Booth si contoare)
    reg       Q_m1;       
    reg [2:0] cnt1;       
    reg [2:0] cnt2;       

    // ==========================================
    // 2. Semnale Control Unit & Adder
    // ==========================================
    wire C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15, C16;
    wire [8:0] adder_in1, adder_in2_base, adder_in2_xor, adder_out;

    // ==========================================
    // 3. Instantiere Control Unit & Adder
    // ==========================================
    control_unit cu_inst (
        .clk(clk), .Begin(begin_op), .Reset(reset),
        .cnt1(cnt1), .cnt2(cnt2), .M7(M_out[7]), .A8(A_out[8]), .A7(A_out[7]), .A6(A_out[6]),
        .Q_0(Q_out[0]), .Q_minus_1(Q_m1), .op(op),
        .C0(C0), .C1(C1), .C2(C2), .C3(C3), .C4(C4), .C5(C5), .C6(C6), .C7(C7),
        .C8(C8), .C9(C9), .C10(C10), .C11(C11), .C12(C12), .C13(C13), .C14(C14), .C15(C15), .C16(C16)
    );

    assign adder_in1 = C13 ? {1'b0, Q_prime_out} : C15 ? {Q_out[7], Q_out} : A_out;
    assign adder_in2_base = C13 ? 9'd1 : C16 ? M_out : (C15 && !C16) ? {Q_prime_out[7], Q_prime_out} : M_out;
    assign adder_in2_xor = adder_in2_base ^ {9{C3}}; // Complement de 2 pt scadere

    CLA_9bit adder_inst (
        .X(adder_in1), .Y(adder_in2_xor), .cin(C3), .Z(adder_out)
    );

    // ==========================================
    // 4. Logica de control a intrarilor pentru Shift Registers
    // ==========================================
    reg [8:0] A_d;  reg A_sh_ld, A_l_r, A_sl, A_sr;
    reg [7:0] Q_d;  reg Q_sh_ld, Q_l_r, Q_sl, Q_sr;
    reg [7:0] Qp_d; reg Qp_sh_ld, Qp_l_r, Qp_sl, Qp_sr;
    reg [8:0] M_d;  reg M_sh_ld, M_l_r, M_sl, M_sr;

    always @(*) begin
        // Valorile DEFAULT: Toate registrele isi fac HOLD (Load propria iesire)
        A_sh_ld = 1'b1;  A_d = A_out;        A_l_r = 1'b0; A_sl = 1'b0; A_sr = 1'b0;
        Q_sh_ld = 1'b1;  Q_d = Q_out;        Q_l_r = 1'b0; Q_sl = 1'b0; Q_sr = 1'b0;
        Qp_sh_ld= 1'b1;  Qp_d = Q_prime_out; Qp_l_r = 1'b0; Qp_sl= 1'b0; Qp_sr = 1'b0;
        M_sh_ld = 1'b1;  M_d = M_out;        M_l_r = 1'b0; M_sl = 1'b0; M_sr = 1'b0;

        if (!reset) begin
            // Reset asincron simulat prin fortarea intrarii D la 0 pe Load
            A_d = 9'b0; Q_d = 8'b0; Qp_d = 8'b0; M_d = 9'b0;
        end else begin
            
            // --- Logica Registrului A ---
            if (C0) begin
                A_d = 9'b0; // Initializeaza
            end else if (C2 && !C13 && !(C15 && !C16)) begin
                A_d = adder_out; // Salveaza adunarea
            end else if (C4) begin
                A_sh_ld = 1'b0; A_l_r = 1'b1; A_sr = A_out[8]; // Shift dreapta Aritmetic
            end else if (C9) begin
                A_sh_ld = 1'b0; A_l_r = 1'b0; A_sl = Q_out[7]; // Shift stanga combinat (SRT)
            end else if (C14) begin
                A_sh_ld = 1'b0; A_l_r = 1'b1; A_sr = 1'b0;     // Shift dreapta Logic
            end

            // --- Logica Registrului Q ---
            if (C1) begin
                Q_d = inbus; // Load din inbus
            end else if (C2 && C15 && !C16) begin
                Q_d = adder_out[7:0]; // Salveaza rezultatul final Q-Q'
            end else if (C4) begin
                Q_sh_ld = 1'b0; Q_l_r = 1'b1; Q_sr = A_out[0]; // Shift dreapta (Booth)
            end else if (C9) begin
                Q_sh_ld = 1'b0; Q_l_r = 1'b0; Q_sl = C10;      // Shift stanga + C10 (SRT)
            end

            // --- Logica Registrului Q' ---
            if (C0) begin
                Qp_d = 8'b0; // Initializeaza
            end else if (C2 && C13) begin
                Qp_d = adder_out[7:0]; // Corectie Q' = Q' + 1
            end else if (C9) begin
                Qp_sh_ld= 1'b0; Qp_l_r = 1'b0; Qp_sl = C11; // Shift stanga + C11 (SRT)
            end

            // --- Logica Registrului M ---
            if (C0) begin
                M_d = {inbus[7], inbus}; // Load extensie de semn
            end else if (C8) begin
                M_sh_ld = 1'b0; M_l_r = 1'b0; M_sl = 1'b0; // Shift stanga (Aliniere SRT)
            end
        end
    end

    // ==========================================
    // 5. Instantierea Registrelor Speciale
    // ==========================================
    u_reg #(.N(9)) reg_A (
        .clk(clk), .l_r(A_l_r), .sh_ld(A_sh_ld), .sr(A_sr), .sl(A_sl), .d(A_d), .q(A_out)
    );

    u_reg #(.N(8)) reg_Q (
        .clk(clk), .l_r(Q_l_r), .sh_ld(Q_sh_ld), .sr(Q_sr), .sl(Q_sl), .d(Q_d), .q(Q_out)
    );

    u_reg #(.N(8)) reg_Q_prime (
        .clk(clk), .l_r(Qp_l_r), .sh_ld(Qp_sh_ld), .sr(Qp_sr), .sl(Qp_sl), .d(Qp_d), .q(Q_prime_out)
    );

    u_reg #(.N(9)) reg_M (
        .clk(clk), .l_r(M_l_r), .sh_ld(M_sh_ld), .sr(M_sr), .sl(M_sl), .d(M_d), .q(M_out)
    );

    // ==========================================
    // 6. Contoare si Q[-1] (Nu au nevoie de u_shift_reg)
    // ==========================================
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

    // ==========================================
    // 7. Magistrala de Iesire
    // ==========================================
    assign outbus = (C6) ? A_out[7:0] : 
                    (C7) ? Q_out[7:0] : 
                    8'bZZZZZZZZ;

endmodule 