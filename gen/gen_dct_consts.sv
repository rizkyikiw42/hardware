module gen_dct_consts();
   // unsigned Q1.(SIZE-2) (plus a 0 sign bit)
   localparam int SIZE = 13;
   localparam real PI = $acos(-1);

   // m1 = cos(4 π / 16)
   localparam signed [SIZE-1:0] m1 = int'($cos(4 * PI / 16) * 2**(SIZE-2));
   // m2 = cos(6 π / 16)
   localparam signed [SIZE-1:0] m2 = int'($cos(6 * PI / 16) * 2**(SIZE-2));
   // m3 = cos(2 π / 16) - cos(6 π / 16)
   localparam signed [SIZE-1:0] m3 = int'(($cos(2 * PI / 16) - $cos(6 * PI / 16)) * 2**(SIZE-2));
   // m4 = cos(2 π / 16) + cos(6 π / 16)
   localparam signed [SIZE-1:0] m4 = int'(($cos(2 * PI / 16) + $cos(6 * PI / 16)) * 2**(SIZE-2));

   initial begin
      $display("localparam int CONST_PREC = %2d;", SIZE);
      $display("localparam signed [CONST_PREC-1:0] m1 = %2d'sh%x;", SIZE, m1);
      $display("localparam signed [CONST_PREC-1:0] m2 = %2d'sh%x;", SIZE, m2);
      $display("localparam signed [CONST_PREC-1:0] m3 = %2d'sh%x;", SIZE, m3);
      $display("localparam signed [CONST_PREC-1:0] m4 = %2d'sh%x;", SIZE, m4);
      $stop;
   end
endmodule // gen_dct_consts
