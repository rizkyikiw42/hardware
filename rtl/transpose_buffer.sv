module transpose_buffer
  (input logic clk, input logic rst, input logic ena_in,
    input logic [11:0] S_in, output logic [11:0] S_out);

  logic [6:0] waddr, raddr;
  logic wren, wbuf, rbuf;
  logic [2:0] xw, yw, xr, yr;

  assign waddr = {wbuf, yw, xw};    // For writing in row-major order
  assign raddr = {rbuf, xr, yr};    // For reading in column-major order

  buf_mem buff (clk, ena_in, S_in, S_out, raddr, waddr, wren);

  enum {START, NEXT, SWITCH} state;

  always_ff @(posedge clk) begin
    if (rst)
      state <= START;
    if (ena_in) begin
      case (state)
        START: begin
          
        end // START
        NEXT: begin
          
        end // NEXT
        SWITCH: begin
          
        end// SWITCH
      endcase
    end // if (ena_in)
  end // always_ff

endmodule // transpose_buffer