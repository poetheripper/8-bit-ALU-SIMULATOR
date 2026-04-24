module up_down_counter_3bit (
    input clk,
    input reset,
    input mode, // 1 for Up, 0 for Down
    output [2:0] count
);
    wire [2:0] q_bar;
    wire [2:0] toggle_signal;

    // The first bit (LSB) always toggles
    assign toggle_signal[0] = 1'b1;

    // Use a generate block for the remaining bits
    genvar i;
    generate
        for (i = 0; i < 3; i = i + 1) begin : counter_gen
            
            // Logic for the toggle signal (J and K) of the next stage
            if (i > 0) begin
                assign toggle_signal[i] = (mode) ? &count[i-1:0] : &q_bar[i-1:0];
            end

            // Instantiate the JK Flip-Flop
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