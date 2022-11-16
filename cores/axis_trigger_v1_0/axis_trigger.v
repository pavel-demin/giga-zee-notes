
`timescale 1 ns / 1 ps

module axis_trigger
(
  // System signals
  input  wire         aclk,
  input  wire         aresetn,

  input  wire [65:0]  din,

  // Master side
  output wire [127:0] m_axis_tdata,
  output wire         m_axis_tvalid,

  output wire [1:0]   test
);

  reg [61:0] int_time_reg;
  reg [65:0] int_data_reg;
  reg int_tvalid_reg;

  always @(posedge aclk)
  begin
    if(~aresetn)
    begin
      int_time_reg <= 62'd0;
      int_data_reg <= 66'd0;
      int_tvalid_reg <= 1'b0;
    end
    else
    begin
      int_time_reg <= int_time_reg + 1'b1;
      int_data_reg <= din;
      int_tvalid_reg <= |din;
    end
  end

  assign m_axis_tdata = {int_time_reg, int_data_reg};
  assign m_axis_tvalid = int_tvalid_reg;

  assign test = {int_data_reg[65], |int_data_reg[15:0]};

endmodule
