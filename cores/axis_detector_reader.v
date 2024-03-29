
`timescale 1 ns / 1 ps

module axis_detector_reader
(
  // System signals
  input  wire         aclk,
  input  wire         aresetn,

  input  wire [65:0]  din,
  input  wire [10:0]  cfg,

  // Master side
  output wire [127:0] m_axis_tdata,
  output wire         m_axis_tvalid
);

  reg [61:0] int_time_reg, int_time_next;
  reg [65:0] int_data_reg, int_data_next;
  reg [7:0] int_cntr_reg, int_cntr_next;
  reg [5:0] int_or_reg, int_or_next;
  reg [2:0] int_sum_reg, int_sum_next;
  reg [2:0] int_case_reg, int_case_next;
  reg int_tvalid_reg, int_tvalid_next;

  always @(posedge aclk)
  begin
    if(~aresetn)
    begin
      int_time_reg <= 62'd0;
      int_data_reg <= 66'd0;
      int_cntr_reg <= 8'd0;
      int_or_reg <= 6'd0;
      int_sum_reg <= 3'd0;
      int_tvalid_reg <= 1'b0;
      int_case_reg <= 3'd0;
    end
    else
    begin
      int_time_reg <= int_time_next;
      int_data_reg <= int_data_next;
      int_cntr_reg <= int_cntr_next;
      int_or_reg <= int_or_next;
      int_sum_reg <= int_sum_next;
      int_tvalid_reg <= int_tvalid_next;
      int_case_reg <= int_case_next;
    end
  end

  always @*
  begin
    int_time_next = int_time_reg + 1'b1;
    int_data_next = int_data_reg;
    int_cntr_next = int_cntr_reg;
    int_or_next = int_or_reg;
    int_sum_next = int_sum_reg;
    int_tvalid_next = int_tvalid_reg;
    int_case_next = int_case_reg;

    case(int_case_reg)
      0:
      begin
        int_data_next = din;
        int_cntr_next = 8'd0;
        int_tvalid_next = 1'b0;
        if(|din)
        begin
          int_case_next = 3'd1;
        end
      end
      1:
      begin
        int_data_next = int_data_reg | din;
        int_cntr_next = int_cntr_reg + 1'b1;
        if(int_cntr_reg >= cfg[7:0])
        begin
          int_case_next = 3'd2;
        end
      end
      2:
      begin
        int_or_next = {int_data_reg[65], int_data_reg[64], |int_data_reg[63:48], |int_data_reg[47:32], |int_data_reg[31:16], |int_data_reg[15:0]};
        int_case_next = 3'd3;
      end
      3:
      begin
        int_sum_next = int_or_reg[5] + int_or_reg[4] + int_or_reg[3] + int_or_reg[2] + int_or_reg[1] + int_or_reg[0];
        int_case_next = 3'd4;
      end
      4:
      begin
        int_tvalid_next = int_sum_reg >= cfg[10:8];
        int_case_next = 3'd0;
      end
    endcase
  end

  assign m_axis_tdata = {int_time_reg, int_data_reg};
  assign m_axis_tvalid = int_tvalid_reg;

endmodule
