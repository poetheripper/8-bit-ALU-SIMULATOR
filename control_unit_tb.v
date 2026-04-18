`timescale 1ns / 1ps

module control_unit_tb ();

    // Semnale de intrare (Registers pt a genera stimuli)
    reg        clk;
    reg        Begin;
    reg        Reset;
    reg  [2:0] cnt1;
    reg  [2:0] cnt2;
    reg        M7;
    reg        A8;
    reg  [1:0] Q_lo;
    reg        q_minus_1;
    reg  [1:0] op;

    // Semnale de iesire (Wires pt a citi din FSM)
    wire C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15, C16;

    // 1. Instantierea UUT (Unit Under Test) cu numele si porturile EXACTE
    control_unit uut (
        .clk(clk),
        .Begin(Begin),
        .Reset(Reset),
        .cnt1(cnt1),
        .cnt2(cnt2),
        .M7(M7),
        .A8(A8),
        .Q_lo(Q_lo),
        .q_minus_1(q_minus_1),
        .op(op),
        .C0(C0), .C1(C1), .C2(C2), .C3(C3), .C4(C4), .C5(C5), .C6(C6), .C7(C7), .C8(C8), 
	.C9(C9), .C10(C10), .C11(C11), .C12(C12), .C13(C13), .C14(C14), .C15(C15), .C16(C16)
    );

    // 2. Generarea semnalului de ceas (T = 10ns)
    always #5 clk = ~clk;

    // 3. Simulare raspuns Datapath (Foarte important pt bucle)
    always @(posedge clk) begin
        if (!Reset) begin
            // Nu resetam contoarele aici, le controlam din blocul 'initial'
        end else begin
            // Bucla Inmultire (S5) - C5 da comanda de incrementare cnt1
            if (C5 && cnt1 < 3'd7) cnt1 <= cnt1 + 1;
            
            // Bucla Impartire (S8) - C12 da comanda de incrementare cnt2
            if (C12 && cnt2 < 3'd7) cnt2 <= cnt2 + 1;
            
            // Aliniere Impartire (S7) - C8 shifteaza M. Simulam ca M[7] devine 1
            if (C8) M7 <= 1'b1; 
            
            // Corectie Rest Impartire (S10) - C14 shifteaza restul. Simulam scaderea cnt1
            if (C14 && cnt1 > 0) cnt1 <= cnt1 - 1;
        end
    end

    // 4. Afisare formatata in consola (Monitorizare)
    always @(posedge clk) begin
        // Afisam doar daca FSM-ul nu este in starea S0 (IDLE)
        if (uut.state != 4'd0) begin
            $display("T=%4t | OP=%2b | Stare=S%-2d | C16..0: %b_%b%b%b%b_%b%b%b%b_%b%b%b%b_%b%b%b%b | Active: %s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", 
                $time, op, uut.state,
                C16, C15, C14, C13, C12, C11, C10, C9, C8, C7, C6, C5, C4, C3, C2, C1, C0,
                C0 ?"C0 " :"", C1 ?"C1 " :"", C2 ?"C2 " :"", C3 ?"C3 " :"", 
                C4 ?"C4 " :"", C5 ?"C5 " :"", C6 ?"C6 " :"", C7 ?"C7 " :"", 
                C8 ?"C8 " :"", C9 ?"C9 " :"", C10?"C10 ":"", C11?"C11 ":"", 
                C12?"C12 ":"", C13?"C13 ":"", C14?"C14 ":"", C15?"C15 ":"", C16?"C16 ":""
            );
        end
    end

    // 5. Scenariul de Testare
    initial begin
        // Initializare semnale
        clk = 0; Begin = 0; Reset = 0; 
        cnt1 = 0; cnt2 = 0; M7 = 0; A8 = 0; Q_lo = 0; q_minus_1 = 0; op = 0;

        // Resetare sistem
        #15 Reset = 1; // Scoatem din reset

        $display("\n=======================================================");
        $display("START TEST: ADUNARE (OP = 00)");
        $display("=======================================================");
        op = 2'b00;
        Begin = 1;          // Impuls de start
        #10 Begin = 0;      // Lasam semnalul jos. FSM va ajunge in S3, apoi S0
        wait(uut.state != 4'd0); // Asteptam sa iasa din S0
        wait(uut.state == 4'd0); // Asteptam sa se intoarca in S0 (Done)
        #20;

        $display("\n=======================================================");
        $display("START TEST: SCADERE (OP = 01)");
        $display("=======================================================");
        op = 2'b01;
        Begin = 1;
        #10 Begin = 0;
        wait(uut.state != 4'd0);
        wait(uut.state == 4'd0);
        #20;

        $display("\n=======================================================");
        $display("START TEST: INMULTIRE Booth (OP = 10)");
        $display("=======================================================");
        op = 2'b10;
        cnt1 = 3'd0; // FSM va bucla in S5 pana cand cnt1 ajunge la 7
        Begin = 1;
        #10 Begin = 0;
        wait(uut.state != 4'd0);
        wait(uut.state == 4'd0);
        #20;

        $display("\n=======================================================");
        $display("START TEST: IMPARTIRE (OP = 11)");
        $display("=======================================================");
        op = 2'b11;
        cnt1 = 3'd3; // Simulam ca M s-a shiftat initial cu 3 pozitii pt aliniere (in S10 o sa se scada)
        cnt2 = 3'd0; // Contorul pt cei 8 pasi de impartire
        M7   = 1'b0; // M[7] e 0 la inceput, va intra in bucla S7 pana cand devine 1
        A8   = 1'b1; // Fortam A8 = 1 la final pt a testa daca se activeaza C13 in starea S9
        Begin = 1;
        #10 Begin = 0;
        wait(uut.state != 4'd0);
        wait(uut.state == 4'd0);
        #20;

        $display("\n=======================================================");
        $display("SIMULARE FINALIZATA CU SUCCES!");
        $display("=======================================================\n");
        $finish;
    end
endmodule