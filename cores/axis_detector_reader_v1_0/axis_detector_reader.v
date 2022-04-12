
`timescale 1 ns / 1 ps

module axis_detector_reader
(
  // System signals
  input  wire         aclk,
  input  wire         aresetn,

  input  wire [63:0]  det_data,
  input  wire [2:0]   cfg_data,

  // Master side
  output wire [127:0] m_axis_tdata,
  output wire         m_axis_tvalid
);

  reg [63:0] int_data_reg[5:0], int_data_next[5:0];
  reg [63:0] int_time_reg, int_time_next;
  reg [3:0] int_cntr_reg, int_cntr_next;
  reg [3:0] int_or_reg, int_or_next;
  reg [2:0] int_sum_reg, int_sum_next;
  reg [2:0] int_case_reg, int_case_next;
  reg int_tvalid_reg, int_tvalid_next;

  always @(posedge aclk)
  begin
    if(~aresetn)
    begin
      int_data_reg[0] <= 64'd0;
      int_data_reg[1] <= 64'd0;
      int_data_reg[2] <= 64'd0;
      int_data_reg[3] <= 64'd0;
      int_data_reg[4] <= 64'd0;
      int_data_reg[5] <= 64'd0;
      int_time_reg <= 64'd0;
      int_cntr_reg <= 4'd0;
      int_or_reg <= 4'd0;
      int_sum_reg <= 4'd0;
      int_case_reg <= 3'd0;
      int_tvalid_reg <= 1'b0;
    end
    else
    begin
      int_data_reg[0] <= int_data_next[0];
      int_data_reg[1] <= int_data_next[1];
      int_data_reg[2] <= int_data_next[2];
      int_data_reg[3] <= int_data_next[3];
      int_data_reg[4] <= int_data_next[4];
      int_data_reg[5] <= int_data_next[5];
      int_time_reg <= int_time_next;
      int_cntr_reg <= int_cntr_next;
      int_or_reg <= int_or_next;
      int_sum_reg <= int_sum_next;
      int_case_reg <= int_case_next;
      int_tvalid_reg <= int_tvalid_next;
    end
  end

  always @*
  begin
    int_data_next[0] = det_data;
    int_data_next[1] = int_data_reg[0];
    int_data_next[2] = int_data_reg[1];
    int_data_next[3] = int_data_reg[2];
    int_data_next[4] = int_data_reg[3];
    int_data_next[5] = int_data_reg[5];
    int_time_next = int_time_reg + 1'b1;
    int_cntr_next = int_cntr_reg;
    int_or_next = int_or_reg;
    int_sum_next = int_sum_reg;
    int_case_next = int_case_reg;
    int_tvalid_next = int_tvalid_reg;

    case(int_case_reg)
      0:
      begin
        if(|int_data_reg[4])
        begin
          int_case_next = 3'd1;
          int_cntr_next = 4'd0;
          int_data_next[5] = int_data_reg[4];
        end
      end
      1:
      begin
        int_cntr_next = int_cntr_reg + 1'b1;
        int_data_next[5] = int_data_reg[5] | int_data_reg[4];
        if(&int_cntr_reg)
        begin
          int_case_next = 3'd2;
        end
      end
      2:
      begin
        int_or_next = {|int_data_reg[5][63:48], |int_data_reg[5][47:32], |int_data_reg[5][31:16], |int_data_reg[5][15:0]};
        int_case_next = 3'd3;
      end
      3:
      begin
        int_sum_next = int_or_reg[3] + int_or_reg[2] + int_or_reg[1] + int_or_reg[0];
        int_case_next = 3'd4;
      end
      4:
      begin
        if(int_sum_reg >= cfg_data)
        begin
          int_tvalid_next = 1'b1;
          int_case_next = 3'd5;
        end
        else
        begin
          int_case_next = 3'd0;
        end
      end
      5:
      begin
        int_tvalid_next = 1'b0;
        int_case_next = 3'd0;
      end
    endcase
  end

  assign m_axis_tdata = {int_time_reg, int_data_reg[5]};
  assign m_axis_tvalid = int_tvalid_reg;

endmodule
