module transpose_buffer
  (input logic CLOCK_50, input logic rst, input logic ena_in,
    input logic [11:0] S_in, output logic [11:0] S_out);

  logic [6:0] waddr, raddr;
  logic wren, wbuf, rbuf;
  logic [2:0] xw, yw, xr, yr;

  assign rbuf = ~wbuf;
  assign waddr = {wbuf, yw, xw};    // For writing in row-major order
  assign raddr = {rbuf, xr, yr};    // For reading in column-major order

  buf_mem buff (CLOCK_50, S_in, S_out, raddr, waddr, wren);

  enum {START, NEXT} state;

  always_ff @(posedge CLOCK_50) begin
    if (rst) begin
      state <= START;
      wren <= 0;
    end

    else begin
      if (ena_in) begin
        wren <= 1;

        case (state)
          START: begin
            wbuf <= 0;
            {xw, yw, xr, yr} <= 0;
            state <= NEXT;
          end // START
          NEXT: begin
            if ({yw, xw} == 6'b111111 && {xr, yr} == 6'b111111) wbuf <= ~wbuf;
            if (xw == 3'b111) yw <= yw + 1;
            if (yr == 3'b111) xr <= xr + 1;
            xw <= xw + 1;
            yr <= yr + 1;
          end // NEXT
        endcase
      end // if (ena_in)

      else wren <= 0;
    end // else begin
  end // always_ff

endmodule // transpose_buffer