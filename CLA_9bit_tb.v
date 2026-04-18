module CLA_9bit_tb();
    reg [8:0] X, Y;
    reg cin;
    wire [8:0] Z;

    // Instantierea Device Under Test (DUT)
    CLA_9bit uut (
        .X(X),
        .Y(Y),
        .cin(cin),
        .Z(Z)
    );

    initial begin
        $display("Time\t X + Y + cin = Z");
        $monitor("%0t\t %d + %d + %b = %d", $time, X, Y, cin, Z);

        X = 9'd0; Y = 9'd0; cin = 0; #10;
        X = 9'd15; Y = 9'd15; cin = 1; #10;   
        X = 9'd110; Y = 9'd145; cin = 0; #10;   
        X = 9'd255; Y = 9'd257; cin = 0; #10;   // daca e mai mare de 511 nu incape overflow

        $finish;
    end
endmodule