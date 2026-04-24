`timescale 1ns / 1ps

module ALU_Top_tb();

    reg clk;
    reg reset;
    reg begin_op;
    reg [1:0] op;
    reg [7:0] inbus;
    
    wire [7:0] outbus;
    reg [15:0] mul_result;

    // Initializarea modului principal
    ALU_Top uut (
        .clk(clk),
        .reset(reset),
        .begin_op(begin_op),
        .op(op),
        .inbus(inbus),
        .outbus(outbus)
    );

    // generare clock
    always #5 clk = ~clk;

    task run_operation;
        input [1:0] cmd_op;
        input [7:0] val_M;
        input [7:0] val_Q;
        input [255:0] nume_operatie; 
        begin
            $display("-> START %s | M = %d, Q = %d", nume_operatie, $signed(val_M), $signed(val_Q));
            
            @(negedge clk); 
            op = cmd_op;
            begin_op = 1; 
            
            @(posedge clk);
            inbus = val_M; // se pune M pe inbus
            begin_op = 0;  
            
            @(posedge clk);
            inbus = val_Q; // se pune Q pe inbus
            
            @(posedge clk);
            
            wait(uut.cu_inst.state == 5'd0);
            
            #30; 
        end
    endtask

    always @(posedge clk) begin
        if (uut.C6) begin
		if(uut.op == 2'b10)
			mul_result[15:8] = outbus;
		else 
            		$display("   [OUTBUS] Rezultat A = %d (bin: %b)", $signed(outbus), outbus);
	end
        if (uut.C7) begin
		if(uut.op == 2'b10) begin	
			mul_result[7:0] = outbus;
			$display("   [OUTBUS] Rezultat AQ = %d (bin: %b)", $signed(mul_result), mul_result);
		end else 
            		$display("   [OUTBUS] Rezultat Q = %d (bin: %b)", $signed(outbus), outbus);
	end
    end

    initial begin
        // Initializare
        clk = 0; reset = 0; begin_op = 0; op = 0; inbus = 0;
        
        #15 reset = 1;
        #15; 
        
        // Adunare
        run_operation(2'b00, 8'd15, 8'd10, "Adunare (15 + 10) = 25");
	run_operation(2'b00, 8'd3, -8'd104, "Adunare (3 + (-104)) = -101");
	run_operation(2'b00, 8'd1, 8'd255, "Adunare (1 + 255) = 255");
	
	// Scadere
	run_operation(2'b01, 8'd20, 8'd15, "Scadere (15 - 20) = -5");
	run_operation(2'b01, 8'd45, 8'd90, "Scadere (90 - 45) =  45");
	run_operation(2'b01, 8'd255, 8'd255, "Scadere (255 - 255) =  0");

        // Inmultire
	run_operation(2'b10, 8'd7, -8'd3, "INMULTIRE BOOTH (7 * -3) = -21");
	run_operation(2'b10, 8'd68, 8'd50, "INMULTIRE BOOTH (68 * 50) = 3400");

        // Impartire
        run_operation(2'b11, 8'd6, 8'd27, "(27 / 6) = 6 * 4 + 3");
        run_operation(2'b11, 8'd15, 8'd100, "(100/15) = 15 * 6 + 10");

        $finish;
    end

endmodule  
