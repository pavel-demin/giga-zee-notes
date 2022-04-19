
`timescale 1 ns / 1 ps

module delay
(
  input  wire        aclk,

  input  wire [15:0] cfg,

  input  wire [63:0] din,

  output wire [63:0] dout
);

  genvar j;

  generate
    for(j = 0; j < 64; j = j + 1)
    begin : BITS
      SRL16E #(
        .INIT(16'h0000)
      ) SRL16E_inst (
        .A0(cfg[j/16*4+0]),
        .A1(cfg[j/16*4+1]),
        .A2(cfg[j/16*4+2]),
        .A3(cfg[j/16*4+3]),
        .CE(1'b1),
        .CLK(aclk),
        .D(din[j]),
        .Q(dout[j])
      );
    end
  endgenerate

endmodule
