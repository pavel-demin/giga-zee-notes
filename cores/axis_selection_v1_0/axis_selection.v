
`timescale 1 ns / 1 ps

module axis_selection
(
  // System signals
  input  wire         aclk,
  input  wire         aresetn,

  input  wire [2:0]   cfg,

  // Slave side
  input  wire [127:0] s_axis_tdata,
  input  wire         s_axis_tvalid,

  // Master side
  output wire [127:0] m_axis_tdata,
  output wire         m_axis_tvalid
);

  reg [127:0] int_tdata_reg;
  reg int_tvalid_reg;

  wire [2:0] int_sum_wire;

  assign int_sum_wire = s_axis_tdata[65] + s_axis_tdata[64] + |s_axis_tdata[63:48] + |s_axis_tdata[47:32] + |s_axis_tdata[31:16] + |s_axis_tdata[15:0];

  always @(posedge aclk)
  begin
    if(~aresetn)
    begin
      int_tdata_reg <= 128'd0;
      int_tvalid_reg <= 1'b0;
    end
    else
    begin
      int_tdata_reg <= s_axis_tdata;
      int_tvalid_reg <= s_axis_tvalid & (int_sum_wire >= cfg);
    end
  end

  assign m_axis_tdata = int_tdata_reg;
  assign m_axis_tvalid = int_tvalid_reg;

endmodule
