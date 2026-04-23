`timescale 1ns / 1ps

module ALU_Top_tb();

    reg clk;
    reg reset;
    reg begin_op;
    reg [1:0] op;
    reg [7:0] inbus;
    
    wire [7:0] outbus;

    // 1. Instantierea Modulului Principal
    ALU_Top uut (
        .clk(clk),
        .reset(reset),
        .begin_op(begin_op),
        .op(op),
        .inbus(inbus),
        .outbus(outbus)
    );

    // 2. Generare Ceas (T = 10ns)
    always #5 clk = ~clk;

    // ========================================================
    // TASK PENTRU AUTOMATIZAREA INCARCARII DATELOR
    // ========================================================
    task run_operation;
        input [1:0] cmd_op;
        input [7:0] val_M;
        input [7:0] val_Q;
        input [255:0] nume_operatie; // DIMENSIUNE DUBLATA pentru a nu trunchia textul
        begin
            $display("\n---------------------------------------------------");
            $display("-> START %s | M = %d, Q = %d", nume_operatie, $signed(val_M), $signed(val_Q));
            $display("---------------------------------------------------");
            
            // Ne pozitionam INTRE doua fronturi pozitive de ceas
            @(negedge clk); 
            op = cmd_op;
            begin_op = 1; // Ridicam flag-ul de start
            
            // Asteptam un ceas. FSM-ul tocmai a intrat in S1 (C0 activ)
            @(posedge clk);
            inbus = val_M; // Punem M pe magistrala ca sa fie prins de MUX
            begin_op = 0;  // Coboram flag-ul
            
            // Asteptam inca un ceas. FSM-ul tocmai a intrat in S2 (C1 activ)
            @(posedge clk);
            inbus = val_Q; // Punem Q pe magistrala ca sa fie prins
            
            // Asteptam sa intre in S3 inainte de a lasa inbus-ul liber
            @(posedge clk);
            
            // Asteptam ca FSM-ul sa termine algoritmul si sa revina in Done (S0)
            wait(uut.cu_inst.state == 5'd0);
            
            // O mica pauza vizuala si buffering inainte de urmatoarea operatie
            #30; 
        end
    endtask

    // ========================================================
    // MONITORIZARE OUTBUS (Iesirea datelor)
    // ========================================================
    always @(posedge clk) begin
        if (uut.C6) 
            $display("   [OUTBUS] Rezultat A = %d (bin: %b)", $signed(outbus), outbus);
        if (uut.C7) 
            $display("   [OUTBUS] Rezultat Q = %d (bin: %b)", $signed(outbus), outbus);
    end

    // ========================================================
    // SCENARIUL PRINCIPAL DE TESTARE
    // ========================================================
    initial begin
        // Initializare
        clk = 0; reset = 0; begin_op = 0; op = 0; inbus = 0;
        
        #15 reset = 1;
        #15; // Pauza de aliniere pentru FSM
        
        // 1. ADUNARE
        run_operation(2'b00, 8'd15, 8'd10, "ADUNARE (15 + 10)");
        
        // 2. SCADERE
        run_operation(2'b01, 8'd15, 8'd20, "SCADERE (15 - 20)");

        // 3. INMULTIRE BOOTH
        run_operation(2'b10, 8'd7, -8'd3, "INMULTIRE BOOTH (7 * -3)");

        // 4. INMULTIRE BOOTH NR NEGATIVE
        run_operation(2'b10, -8'd10, 8'd6, "INMULTIRE BOOTH (-10 * 6)");

        // ---------------------------------------------------
        // 5. IMPARTIRE SRT (OP = 11) - NOU
        // ---------------------------------------------------
        // Valoarea M (Impartitorul) = 6
        // Valoarea Q (Deimpartitul) = 27
        // Asteptari matematice: Catul (Q) = 4, Restul (A) = 3
        run_operation(2'b11, 8'd6, 8'd27, "IMPARTIRE SRT (27 / 6)");

        // Inca un test de impartire ca sa fim siguri
        // 100 / 15 -> Cat: 6, Rest: 10
        run_operation(2'b11, 8'd15, 8'd100, "IMPARTIRE SRT (100 / 15)");

        $display("\n=======================================================");
        $display("          SIMULARE FINALIZATA CU SUCCES!               ");
        $display("=======================================================\n");
        $finish;
    end
 
endmodule 