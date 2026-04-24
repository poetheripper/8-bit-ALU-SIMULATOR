`timescale 1ns / 1ps

module control_unit_tb();

    //Declarare reg
    reg clk;
    reg Begin;
    reg Reset;
    reg [2:0] cnt1;
    reg [2:0] cnt2;
    reg M7, A8, A7, A6, Q_0, Q_minus_1;
    reg [1:0] op;

    //Declarare wire pentru semnale de control
    wire C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15, C16;

    //Instantiere control unit
    control_unit uut (
        .clk(clk),
        .Begin(Begin),
        .Reset(Reset),
        .cnt1(cnt1), .cnt2(cnt2),
        .M7(M7), .A8(A8), .A7(A7), .A6(A6),
        .Q_0(Q_0), .Q_minus_1(Q_minus_1),
        .op(op),
        .C0(C0), .C1(C1), .C2(C2), .C3(C3), .C4(C4), .C5(C5), 
        .C6(C6), .C7(C7), .C8(C8), .C9(C9), .C10(C10), .C11(C11), 
        .C12(C12), .C13(C13), .C14(C14), .C15(C15), .C16(C16)
    );

    
    always #5 clk = ~clk;

    always @(posedge clk or negedge Reset) begin
        if (!Reset) cnt1 <= 3'd0;
        else if (Begin) cnt1 <= 3'd0;        //la inceputul fiecarei operati se pune cnt1 pe 0
        else if (C5) cnt1 <= cnt1 + 1;       // Incrementare in MUL numarul de pasi (7)
        else if (C8) cnt1 <= cnt1 + 1;       //Incrementare in DIV k leading 0 s   
        else if (C14) cnt1 <= cnt1 - 1;      // Decrementare in DIV (shiftam de k ori)
    end

    always @(posedge clk or negedge Reset) begin
        if (!Reset) cnt2 <= 3'd0;
        else if (Begin) cnt2 <= 3'd0;          //la inceputul fiecarei operati se pune cnt2 pe 0
        else if (C12) cnt2 <= cnt2 + 1;      // Incrementare in DIV numarul de pasi (7)
    end

    
    initial begin
        // Initializare inputuri pe zero
        clk = 0;
        Begin = 0;
        Reset = 0;
        cnt1 = 0;
        cnt2 = 0;
  
        M7 = 0; A8 = 0; A7 = 0; A6 = 0;
        Q_0 = 0; Q_minus_1 = 0;
        op = 2'b00;

        
        #15;
        Reset = 1;
        $display("Time: %0t | Suntem in S0.", $time);

        // TEST1: Adunare (op = 00)
        #10;
        $display("Time: %0t | [TEST 1] Incepe Adunare", $time);
        op = 2'b00; 
        Begin = 1;   
        #10 Begin = 0; 

        //asteptam 8 cc ca sa parcurgem starile S1->S2->S3->S4->S8->S9->S0
        #80;

        // TEST2: Subtraction (op = 01)
        $display("Time: %0t | [TEST 2] Incepe Scaderea", $time);
        op = 2'b01;
        Begin = 1;
        #10 Begin = 0;

        //8 cc
        #80;

        //TEST3: Inmultire (op = 10)
        $display("Time: %0t | [TEST 3] Incepe Inmultirea op", $time);
        op = 2'b10;
        Q_0 = 1; Q_minus_1 = 0; //mergem in S5(scadere) in interiorul lui S6
        
        
        
        Begin = 1;
        #10 Begin = 0;

        //asteptam cei 7 pasi 
        #300;

        //TEST4: Impartire (op = 11) 
        $display("Time: %0t | [TEST 4] Starting DIV operation...", $time);
        op = 2'b11;
        
        
        M7 = 0; 
        // ultimi 3 biti ai lui A sunt egali
        A8 = 0; A7 = 0; A6 = 0; 
        
        Begin = 1;
        #10 Begin = 0;

        
        #40;
        
        $display("Time: %0t | [TEST 4] Punem M[7] ca sa iesim din loop", $time);
        M7 = 1; // Now it will jump to S11 on the next clock edge!

        //aasteptam pana cnt2 ajunge la 7
        #300;

        $display("\nTime: %0t | Am terminat", $time);
        $stop; 
    end

    
    initial begin
        $display("======================================================================================================");
        $display("  Time  | op | ST | C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 C10 C11 C12 C13 C14 C15 C16 | cnt1 | cnt2 ");
        $display("======================================================================================================");
        $monitor("%6t | %b | %-2d |  %b  %b  %b  %b  %b  %b  %b  %b  %b  %b   %b   %b   %b   %b   %b   %b   %b  |  %d   |  %d", 
                 $time, op, uut.state, 
                 C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15, C16, 
                 cnt1, cnt2);
    end

endmodule