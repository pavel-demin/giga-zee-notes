
`timescale 1 ns / 1 ps

module edge_detector
(
  input  wire        aclk,

  input  wire [65:0] din,

  output wire [65:0] dout
);

  reg [65:0] int_data_reg[2:0];

  wire [65:0] int_data_wire;

  xpm_cdc_array_single #(
    .DEST_SYNC_FF(4),
    .INIT_SYNC_FF(0),
    .SRC_INPUT_REG(0),
    .SIM_ASSERT_CHK(0),
    .WIDTH(66)
  ) cdc_0 (
    .src_in(din),
    .src_clk(),
    .dest_out(int_data_wire),
    .dest_clk(aclk)
  );

  always @(posedge aclk)
  begin
    int_data_reg[0] <= ~int_data_wire;
    int_data_reg[1] <= int_data_reg[0];
    int_data_reg[2] <= int_data_reg[1] & ~int_data_reg[0];
  end

  assign dout = int_data_reg[2];

endmodule
