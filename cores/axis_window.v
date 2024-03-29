
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

  reg [127:0] int_tdata_reg, int_tdata_next;
  reg [7:0] int_cntr_reg, int_cntr_next;
  reg int_tvalid_reg, int_tvalid_next;

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
      int_tdata_reg <= int_tdata_next;
      int_cntr_reg <= int_cntr_next;
      int_tvalid_reg <= int_tvalid_next;
    end
  end

  always @*
  begin
    int_tdata_next = int_tdata_reg;
    int_cntr_next = int_cntr_reg;
    int_tvalid_next = int_tvalid_reg;

    if(|int_cntr_reg)
    begin
      int_cntr_next = int_cntr_reg - 1'b1;
    end

    if(s_axis_tvalid & ~|int_cntr_reg)
    begin
      int_cntr_next = cfg;
    end

    int_tdata_next = s_axis_tdata;
    int_tvalid_next = |int_cntr_reg | s_axis_tvalid;
  end

  assign m_axis_tdata = int_tdata_reg;
  assign m_axis_tvalid = int_tvalid_reg;

endmodule
