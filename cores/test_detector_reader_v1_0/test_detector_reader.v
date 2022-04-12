
`timescale 1 ns / 1 ps

module test_detector_reader
(
  // System signals
  input  wire         aclk,
  input  wire         aresetn,

  input  wire [63:0]  det_data,

  output wire [1:0]   test_data
);

  reg [63:0] int_data_reg[5:0], int_data_next[5:0];
  reg [3:0] int_cntr_reg, int_cntr_next;
  reg int_case_reg, int_case_next;

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
      int_cntr_reg <= 4'd0;
      int_case_reg <= 3'd0;
    end
    else
    begin
      int_data_reg[0] <= int_data_next[0];
      int_data_reg[1] <= int_data_next[1];
      int_data_reg[2] <= int_data_next[2];
      int_data_reg[3] <= int_data_next[3];
      int_data_reg[4] <= int_data_next[4];
      int_data_reg[5] <= int_data_next[5];
      int_cntr_reg <= int_cntr_next;
      int_case_reg <= int_case_next;
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
    int_cntr_next = int_cntr_reg;
    int_case_next = int_case_reg;

    case(int_case_reg)
      0:
      begin
        int_cntr_next = 4'd0;
        int_data_next[5] = int_data_reg[4];
        if(|int_data_reg[4])
        begin
          int_case_next = 1'b1;
        end
      end
      1:
      begin
        int_cntr_next = int_cntr_reg + 1'b1;
        int_data_next[5] = int_data_reg[5] | int_data_reg[4];
        if(&int_cntr_reg)
        begin
          int_case_next = 1'b0;
        end
      end
    endcase
  end

  assign test_data = {|int_data_reg[5][63:48], |int_data_reg[5][47:32]};

endmodule
