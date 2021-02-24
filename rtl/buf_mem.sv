module buf_mem
  (input logic clk,
    input logic [11:0] S_in, output logic [11:0] S_out,
    input logic [6:0] raddr, input logic [6:0] waddr, input logic wren);

  logic signed [11:0] buf1 [0:7][0:7];
  logic signed [11:0] buf2 [0:7][0:7];

  logic [2:0] xr, yr, xw, yw;

  assign xr = raddr[5:3];   // Read x coordinate
  assign yr = raddr[2:0];   // Read y coordinate
  assign yw = waddr[5:3];   // Write x coordinate
  assign xw = waddr[2:0];   // Write y coordinate

  always_ff @(posedge clk) begin
    if (wren) begin
      if (~waddr[6])
        buf1[yw][xw] <= S_in;
      else
        buf2[yw][xw] <= S_in;
    end // if (wren)

    if (~raddr[6])
      S_out <= buf1[yr][xr];
    else
      S_out <= buf2[yr][xr];
  end // always_ff

endmodule // buf_mem


