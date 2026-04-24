module up_down_counter_3bit (
    input clk,
    input reset,
    input mode, // 1 - incrementare / 0 - decrementare
    output [2:0] count
);
    wire [2:0] q_bar;
    wire [2:0] toggle_signal;

    // primul bit mereu e 1
    assign toggle_signal[0] = 1'b1;

    genvar i;
    generate
        for (i = 0; i < 3; i = i + 1) begin : counter_gen
            
            // logica de numarare pentru urmatorul bit
            if (i > 0) begin
                assign toggle_signal[i] = (mode) ? &count[i-1:0] : &q_bar[i-1:0];
            end

            // instantiere modul jk flip-flop
            JK_flip_flop ff (
                .j(toggle_signal[i]),
                .k(toggle_signal[i]),
                .clk(clk),
                .rst(reset),
                .q(count[i]),
                .q_bar(q_bar[i])
            );
        end
    endgenerate

endmodule
