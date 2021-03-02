module 2d_dct (
    input logic clk, input logic rst,
    input logic [7:0] in, output logic [14:0] out,
    input ena_in
);

  logic trb_enable, 1d_dct_ena1, 1d_dct_ena2;
  logic [11:0] first_out, second_in;

  dct_1d first (clk, rst, 1d_dct_ena1, in, first_out);
  dct_1d second (clk, rst, 1d_dct_ena2, second_in, out); // Change for correct parametrization.
  transpose_buffer trb (clk, rst, trb_enable, first_out, second_in);

  logic [7:0] count1, count2;
  enum {START, TRB_BEGIN, DCT2_1D_BEGIN} state;

  localparam [7:0] 1d_dct_latency = 8'd48;
  localparam [7:0] trb_latency = 8'd64;

  always @(posedge clk) begin
    if (rst) begin
      count1 <= 0;
      count2 <= 0;
      trb_enable <= 0;
      1d_dct_ena1 <= 0;
      1d_dct_ena2 <= 0;
      state <= START;
    end // if (rst)

    else begin
      case (state)
        START: begin
          1d_dct_ena1 <= 1;
          count1 <= count1 + 1;
          if (count1 == 1d_dct_latency - 1) state <= TRB_BEGIN;
        end
        TRB_BEGIN: begin
          trb_enable <= 1;
          count2 <= count2 + 1;
          if (count2 == trb_latency - 1) state <= DCT2_1D_BEGIN;
        end
        DCT2_1D_BEGIN: begin
          1d_dct_ena2 <= 1;
        end
      endcase
    end // else
  end // always

endmodule // 2d_dct
