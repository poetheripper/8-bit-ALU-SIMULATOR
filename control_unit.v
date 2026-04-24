module control_unit (
    input        clk,
    input        Begin,     
    input        Reset,     
    
    input  [2:0] cnt1,      
    input  [2:0] cnt2,      
    input        M7,        // Bitul de semn al lui M
    input        A8,        
    input        A7,
    input        A6,
    input  	 Q_0,      // Q[0]
    input        Q_minus_1, // Q[-1]
    input  [1:0] op,        // 00-add, 01-sub, 10-mul, 11-div
    // Semnale de control (C0 ... C16)
    output reg C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15, C16
);

    // Codificarea Starilor (S0 -> S16)
    localparam S0  = 5'd0,
               S1  = 5'd1,
               S2  = 5'd2,
               S3  = 5'd3,
               S4  = 5'd4,
               S5  = 5'd5,
               S6  = 5'd6,
               S7  = 5'd7,
               S8  = 5'd8,
               S9  = 5'd9,
               S10 = 5'd10,
               S11 = 5'd11,
	       S12 = 5'd12,
	       S13 = 5'd13,
	       S14 = 5'd14,
	       S15 = 5'd15,
	       S16 = 5'd16;

    reg [4:0] state, next_state;
    reg corectie = 1'b0;
    
    always @(posedge clk or negedge Reset) begin
        if (!Reset) begin
            state <= S0;
        end else begin
            state <= next_state;
        end
    end

    //Logica pentru Starea Urmatoare si Semnale de Control (Combinational)
    always @(*) begin
        // Initializare default
        next_state = state;
        {C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15, C16} = 17'b0;

        case (state)
            S0: begin
                if (Begin) next_state = S1;
            end

            S1: begin
                C0 = 1'b1; // Load M
		next_state = S2;
            end
            
            S2: begin
		C1 = 1'b1;
		next_state = S3;
            end

	    S3: begin
                case (op)
                    2'b00: next_state = S4;  // ADD
                    2'b01: next_state = S5;  // SUB
                    2'b10: next_state = S6;  // MUL
                    2'b11: next_state = S10;  // DIV
                endcase
	    end
	
	    // Adunare
	    S4: begin
                C2 = 1'b1; // Comanda adunarea
		if(corectie == 1'b1) begin
		     next_state = S14;
		end if (op == 2'b10) begin               
		     next_state = S7; // merge inapoi in algoritmul de inmultire
                end else if( op == 2'b11) begin
		     next_state = S12;
                end else begin
		     C15 = 1'b1;
		     next_state = S8; // outbus A;
		end
            end

            // Scadere
            S5: begin
		C2 = 1'b1; // Comanda adunare
                C3 = 1'b1; // Comanda scaderea (Seteaza c_in = 1 si mux-ul lui M in ~M)

		if (op == 2'b10) begin               
		         next_state = S7; // merge inapoi in algoritmul de inmultire
                end else if( op == 2'b11) begin
			 next_state = S12; // merge inapoi in algoritmul de impartire
                end else begin
			 C15 = 1'b1;
			 next_state = S8; // outbus A;
		end
            end

            // Inmultire - Booth radix-2
            S6: begin   
		case({Q_0, Q_minus_1})
			2'b01: next_state = S4;
			2'b10: next_state = S5;
		        default: next_state = S7;
		endcase
            end

            // stare pentru shiftare si incrementare cnt1 dupa adunare/scadere la inmultire
            S7: begin	
                C4 = 1'b1;

		if(cnt1 == 3'd7) begin
		         next_state = S8;
		end else begin
			 C5 = 1'b1; // incrementare cnt1
			 next_state = S6;
		end
            end

            S10: begin
                if(M7 == 1'b0) begin
			  C8 = 1'b1; // incrementare cnt1 la shiftare stanga k biti
			  next_state = S10;
		end else begin
		          next_state = S11;
		end
            end

            S11: begin
	        C9 = 1'b1;
                if(A8 == A7 && A7 == A6) begin
		          next_state = S12;
		end else if(A8 == 1'b0) begin
			  C10 = 1'b1;
			  next_state = S5; // scadere A - M
		end else begin
			  C11 = 1'b1;
			  next_state = S4; // adunare A + M
	        end
            end

	    S12: begin
		if(cnt2 == 3'd7) begin
	 		  next_state = S13;
		end else begin
			  C12 = 1'b1; // incrementare cnt2
			  next_state = S11;
		end
	    end

	    S13: begin
		if(A8 == 1'b1) begin
			  next_state = S14; // corectie
		end else begin
			  next_state = S15;
		end
	    end

	    S14: begin
		// partea asta incrementeaza Q', doar atat!!!!
		C13 = 1'b1; // selecteaza Q'8
		C16 = 1'b1; // selecteaza 1
		C2 = 1'b1;
		corectie = 1'b1;
		// corectie: se aduna A + M
		next_state = S4;
	    end

	    S15: begin
		if(cnt1 == 1'd0) begin
			  next_state = S16;
		end else begin
			  // shifteaza restul la dreapta - pune biti de 0
			  C14 = 1'b1; // decrementeaza cnt1 la shiftare dreapta cu k biti
			  next_state = S15;
		end
	    end
		
	    S16: begin
		C2 = 1'b1;
		C3 = 1'b1;
		C15 = 1'b1;
		C16 = 1'b1;
		next_state = S8;
	    end

            
            S8: begin
		C6 = 1'b1; // trimite rezultatul din A pe outbus
		next_state = S9;
            end

	    S9: begin
		C7 = 1'b1; // trimite rezultatul din Q pe outbus
            	if (!Begin) next_state = S0;
	    end

            default: next_state = S0;
        endcase
    end

endmodule  
