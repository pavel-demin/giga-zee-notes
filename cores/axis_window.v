
`timescale 1 ns / 1 ps

module axis_window
(
  // System signals
  input  wire         aclk,
  input  wire         aresetn,

  input  wire [7:0]   cfg,

  // Slave side
  input  wire [127:0] s_axis_tdata,
  input  wire         s_axis_tvalid,

  // Master side
  output wire [127:0] m_axis_tdata,
  output wire         m_axis_tvalid
);

  reg [127:0] int_tdata_reg;
  reg [7:0] int_cntr_reg = 8'd0;
  reg int_tvalid_reg = 1'b0;

  wire int_enbl_wire = |int_cntr_reg;

  always @(posedge aclk)
  begin
    if(~aresetn)
    begin
      int_tdata_reg <= 128'd0;
      int_cntr_reg <= 8'd0;
      int_tvalid_reg <= 1'b0;
    end
    else
    begin
      int_tdata_reg <= s_axis_tdata;

      if(int_enbl_wire)
      begin
        int_cntr_reg <= int_cntr_reg - 1'b1;
      end
      else if(s_axis_tvalid)
      begin
        int_cntr_reg <= cfg;
      end

      int_tvalid_reg <= int_enbl_wire | s_axis_tvalid;
    end
  end

  assign m_axis_tdata = int_tdata_reg;
  assign m_axis_tvalid = int_tvalid_reg;

endmodule
