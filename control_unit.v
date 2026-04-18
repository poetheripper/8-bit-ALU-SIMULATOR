module control_unit (
    input        clk,
    input        Begin,     // Semnalul BEGIN din diagrama (active high)
    input        Reset,     // Asincron, active low
    // Semnale de status din Datapath
    input  [2:0] cnt1,      // Presupunem 3 biti pt a numara pana la 7
    input  [2:0] cnt2,      // Presupunem 3 biti pt a numara pana la 7
    input        M7,        // Bitul de semn al lui M
    input        A8,        // Bitul de semn al lui A (inlocuieste nevoia de a sparge bus-ul aiurea)
    input  [1:0] Q_lo,      // Q[1:0] pentru Booth (daca e nevoie)
    input        q_minus_1, // Q[-1] redenumit corect sintactic
    input  [1:0] op,        // 00-add, 01-sub, 10-mul, 11-div
    // Semnale de control (C1..C15, plus C0 pe care l-ai definit in cod)
    output reg C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15, C16
);

    // Codificarea Starilor (S0 -> S11)
    localparam S0  = 4'd0,
               S1  = 4'd1,
               S2  = 4'd2,
               S3  = 4'd3,
               S4  = 4'd4,
               S5  = 4'd5,
               S6  = 4'd6,
               S7  = 4'd7,
               S8  = 4'd8,
               S9  = 4'd9,
               S10 = 4'd10,
               S11 = 4'd11;

    reg [3:0] state, next_state;

    // 1. Registrul de Stare (Secvential)
    always @(posedge clk or negedge Reset) begin
        if (!Reset) begin
            state <= S0;
        end else begin
            state <= next_state;
        end
    end

    // 2. Logica pentru Starea Urmatoare si Semnale de Control (Combinational)
    always @(*) begin
        // Initializare default pentru a evita latch-urile nedorite
        next_state = state;
        {C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15, C16} = 17'b0;

        case (state)
            S0: begin
                if (Begin) next_state = S1;
            end

            S1: begin
                // In S1 facem Load/Init conform intentiei tale initiale
                C0 = 1'b1; // Load M (presupunere din codul tau)
                C1 = 1'b1; // Load Q (presupunere din codul tau)
                
                case (op)
                    2'b00: next_state = S2;  // ADD
                    2'b01: next_state = S4;  // SUB
                    2'b10: next_state = S5;  // MUL
                    2'b11: next_state = S6;  // DIV
                endcase
            end

            // --- ADUNARE ---
            S2: begin
                C2 = 1'b1; // Comanda adunarea
		C15 = 1'b1; // Selectie Q
		C16 = 1'b1; // Selectie M
                next_state = S3;
            end

            // --- SCADERE ---
            S4: begin
		C2 = 1'b1; // Comanda adunare
                C3 = 1'b1; // Comanda scaderea (Seteaza c_in = 1 si mux-ul lui M in ~M)
		C15 = 1'b1; // Selectie Q
		C16 = 1'b1; // Selectie M
                next_state = S3;
            end

            // --- INMULTIRE (Booth) ---
            S5: begin
                // Aici va trebui sa adaugi logica pentru cei 8 pasi de inmultire Booth.
                // Diagrama ta de st?ri face salt direct S5 -> S3, ceea ce inseamna ca 
                // lipseste o bucla (un loop conditionat de CNT1) in diagrama desenata.
                // Exemplu sumar (trebuie adaptat dupa cum activezi semnalele de add/sub/shift):
                
                C4 = 1'b1; // Shiftare la dreapta
                C5 = 1'b1; // Incrementare CNT1

                if (cnt1 == 3'd7) begin
                    next_state = S3;
                end else begin
                    next_state = S5; // Ramane in bucla pana cand cnt1 ajunge la 7
                end
            end

            // --- IMPARTIRE ---
            S6: begin
                // Initializare pt impartire
                if (M7 == 1'b0) next_state = S7;
                else next_state = S3; // Ce se intampla daca impartitorul e negativ? Diagrama ta nu arata.
            end

            S7: begin
                // Aliniere stanga pana cand M[7] == 1
                if (M7 == 1'b0) begin
                    C8 = 1'b1; // Shift left M (sau ce face C8 exact)
                    C9 = 1'b1; // Shift left AQ
                    next_state = S7; // Bucla
                end else begin
                    next_state = S8;
                end
            end

            S8: begin
                // Baza algoritmului de impartire (Sub/Add si Shift)
                C12 = 1'b1; // Increment CNT2
                
                if (cnt2 < 3'd7) begin
                    next_state = S8; // Ramane in bucla
                end else begin
                    next_state = S9;
                end
            end

            S9: begin
                if (cnt2 == 3'd7 && A8 == 1'b1) begin
                    C13 = 1'b1; // Corectie Q' (din codul tau)
                    next_state = S10;
                end else begin
                    next_state = S10;
                end
            end

            S10: begin
                // Corectie / Shiftare rest la final
                if (cnt1 != 3'd0) begin
                    C14 = 1'b1; // Shift inapoi restul
                    // C15 = 1'b1; // Logica ta zicea si de C15
                    next_state = S10; // Bucla
                end else begin
                    next_state = S11;
                end
            end

            S11: begin
                next_state = S3;
            end

            // --- DONE ---
            S3: begin
                // Aici ALU isi termina treaba. 
                // Asteapta ca semnalul BEGIN sa cada pe 0 pentru a se intoarce in S0.
		C6 = 1'b1; // trimite rezultatul din A pe outbus
		C7 = 1'b1; // trimite rezultatul din Q pe outbus
                if (!Begin) next_state = S0;
            end

            default: next_state = S0;
        endcase
    end

endmodule 