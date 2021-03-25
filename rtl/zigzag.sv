// Input is in column-major order, output is in zigzag.  Pipelined.
//
// Input order:
//    0  8 16 24 32 40 48 56
//    1  9 17 25 33 41 49 57
//    2 10 18 26 34 42 50 58
//    3 11 19 27 35 43 51 59
//    4 12 20 28 36 44 52 60
//    5 13 21 29 37 45 53 61
//    6 14 22 30 38 46 54 62
//    7 15 23 31 39 47 55 63
//
// Output order:
//    0  1  5  6 14 15 27 28
//    2  4  7 13 16 26 29 42
//    3  8 12 17 25 30 41 43
//    9 11 18 24 31 40 44 53
//   10 19 23 32 39 45 52 54
//   20 22 33 38 46 51 55 60
//   21 34 37 47 50 56 59 61
//   35 36 48 49 57 58 62 63

module zigzag(input logic clk, input logic rst,
              input logic ena_in, output logic ena_out,
              input logic rdy_in, output logic rdy_out,
              input logic [10:0] in, output logic [10:0] out);

   logic [10:0] coefs[2][64];
   logic active_in;
   logic valid_out;

   logic [5:0] idx_in;

   logic [2:0] idx_out_x;
   logic [2:0] idx_out_y;
   logic [2:0] idx_out_x_n;
   logic [2:0] idx_out_y_n;
   logic [5:0] idx_out_n;
   assign idx_out_n = {idx_out_x_n, idx_out_y_n};

   enum logic [1:0] { RIGHT, DOWNLEFT, UPRIGHT } dir;

   assign rdy_out = idx_in != '1 || !valid_out;
   assign ena_out = rdy_in && valid_out;

   always_ff @(posedge clk)
     if (rst) begin
        active_in <= '0;
        valid_out <= '0;
        idx_in <= '0;
        {idx_out_x, idx_out_y} <= '0;
        dir <= RIGHT;
     end else begin
        if (ena_in) begin
           coefs[active_in][idx_in] <= in;
           idx_in <= idx_in + 6'b1;
           // Done this block.
           if (idx_in == '1) begin
              active_in = !active_in;
              valid_out <= '1;
           end
        end

        out <= coefs[!active_in][ena_out ? idx_out_n : '0];
        if (ena_out) begin
           idx_out_x <= idx_out_x_n;
           idx_out_y <= idx_out_y_n;

           if (idx_out_x == '1 && idx_out_y == '1) begin
              dir <= RIGHT;
              valid_out <= '0;
           end else
             case (dir)
               RIGHT: dir <= DOWNLEFT;

               DOWNLEFT:
                 if (idx_out_y == '1)
                   dir <= UPRIGHT;
                 else if (idx_out_x == '0)
                   dir <= UPRIGHT;

               UPRIGHT:
                 if (idx_out_x == '1)
                   dir <= DOWNLEFT;
                 else if (idx_out_y == '0)
                   dir <= DOWNLEFT;
             endcase // case (dir)
        end
     end

   always_comb
     if (idx_out_x == '1 && idx_out_y == '1)
       {idx_out_x_n, idx_out_y_n} = '0;
     else begin
        {idx_out_x_n, idx_out_y_n} = {idx_out_x, idx_out_y};

        case (dir)
          RIGHT: idx_out_x_n = idx_out_x + 3'b1;

          DOWNLEFT:
            if (idx_out_y == '1)
              idx_out_x_n = idx_out_x + 3'b1;
            else if (idx_out_x == '0)
              idx_out_y_n = idx_out_y + 3'b1;
            else begin
               idx_out_x_n = idx_out_x - 3'b1;
               idx_out_y_n = idx_out_y + 3'b1;
            end

          UPRIGHT:
            if (idx_out_x == '1)
              idx_out_y_n = idx_out_y + 3'b1;
            else if (idx_out_y == '0)
              idx_out_x_n = idx_out_x + 3'b1;
            else begin
               idx_out_x_n = idx_out_x + 3'b1;
               idx_out_y_n = idx_out_y - 3'b1;
            end
        endcase // case (dir)
     end

endmodule // zigzag
