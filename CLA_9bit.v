module CLA_9bit(
  input [8:0] X,   //9 biti
  input [8:0] Y,
  input cin,
  output [8:0] Z


);

wire [8:0] gn1, pn1;   //semnalele de generate si propagate pentru nivelul 1 de celule BC
wire [6:0] gn2, pn2;  //pt nivelul 2
wire [4:0] gn3, pn3;

wire [8:0] c;               //nu ma intereseaza carry 9
  
assign c[0] = cin;

genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : ACcells  //pentru celulele AC
            AC cell_ac (
                .xi(X[i]),
                .yi(Y[i]),
                .ci(c[i]),
                .Gii(gn1[i]),      //G00 = gn1[0]
                .Pii(pn1[i]),      //P00 = pn1[0]
                .zi(Z[i])
            );
        end
        
        for (i = 0; i < 8; i = i + 2) begin : BCLevel1    //pentru primul nivel BC
            BC bc1 (
            .ci(c[i]),
            .Gij(gn1[i]),     //Gi,i
            .Pij(pn1[i]),     //Pi,i
            .Ghk(gn1[i+1]),   // Gi+1,i+1
            .Phk(pn1[i+1]),   // Pi+1,i+1
            .ch(c[i+1]),      //c1 , c3, c5, c7  
            .Gik(gn2[i]),     //G01, G23, G45, G67
            .Pik(pn2[i])      //P01,  P23, P45, P67
             );
             
        end
        
        for (i = 0; i < 5; i = i + 4) begin : BCLevel2 //pentru al doilea nivel BC
            BC bc2 (
            .ci(c[i]),
            .Gij(gn2[i]),     //Gi,i+1
            .Pij(pn2[i]),     //Pi,i+1
            .Ghk(gn2[i+2]),   // Gi+1,i+1
            .Phk(pn2[i+2]),   // Pi+1,i+1
            .ch(c[i+2]),      //c2 , c6  
            .Gik(gn3[i]),     //G03, G47
            .Pik(pn3[i])      //P03,  P47, 
            );
            
        end
    endgenerate
    
/* 

BC bc0 (
        .ci(c[0]),
        .Gij(gn1[0]),  //G00
        .Pij(pn1[0]),  //P00
        .Ghk(gn1[1]), // G11
        .Phk(pn1[1]), // P11
        .ch(c[1])  
);

*/

    
wire G07, P07;

BC bc3 (
            .ci(c[0]),
            .Gij(gn3[0]),     //G03
            .Pij(pn3[0]),     //P03
            .Ghk(gn3[4]),   // G47
            .Phk(pn3[4]),   // P47
            .ch(c[4]),      //c4 
            .Gik(G07),     
            .Pik(P07)      
);
    
assign c[8] = G07 | ( P07 & c[0]);

AC finalAC(
            .xi(X[8]),
            .yi(Y[8]),
            .ci(c[8]),
            .Gii(),      //nu mai avem nevoie de ele
            .Pii(),     
            .zi(Z[8])       
              
);

endmodule

module AC (
    input xi,
    input yi,
    input ci,
    output Gii,
    output Pii,
    output zi
);

assign Gii = xi & yi;
assign Pii = xi | yi;
assign zi = xi ^ yi ^ ci;

endmodule

module BC(
  input ci,
  input Gij,
  input Pij,
  input Ghk,    //h = j + 1
  input Phk,
  output Gik,
  output Pik,
  output ch
  
);

assign Gik = Ghk | (Gij & Phk);
assign Pik = Phk & Pij;
assign ch =  Gij | (Pij & ci);

endmodule


