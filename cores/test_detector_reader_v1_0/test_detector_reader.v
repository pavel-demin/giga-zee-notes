
`timescale 1 ns / 1 ps

module test_detector_reader
(
  // System signals
  input  wire         aclk,
  input  wire         aresetn,

  input  wire [63:0]  det_data,

  output wire [1:0]   test_data
);

  reg [63:0] int_data_reg, int_data_next;
  reg [3:0] int_cntr_reg, int_cntr_next;
  reg int_case_reg, int_case_next;

  wire [63:0] int_data_wire;

  xpm_cdc_array_single #(
    .DEST_SYNC_FF(4),
    .INIT_SYNC_FF(0),
    .SRC_INPUT_REG(0),
    .SIM_ASSERT_CHK(0),
    .WIDTH(64)
  ) cdc_0 (
    .src_in(det_data),
    .src_clk(),
    .dest_out(int_data_wire),
    .dest_clk(aclk)
  );

  always @(posedge aclk)
  begin
    if(~aresetn)
    begin
      int_data_reg <= 64'd0;
      int_cntr_reg <= 4'd0;
      int_case_reg <= 1'b0;
    end
    else
    begin
      int_data_reg <= int_data_next;
      int_cntr_reg <= int_cntr_next;
      int_case_reg <= int_case_next;
    end
  end

  always @*
  begin
    int_data_next = int_data_reg;
    int_cntr_next = int_cntr_reg;
    int_case_next = int_case_reg;

    case(int_case_reg)
      0:
      begin
        int_cntr_next = 4'd0;
        int_data_next = int_data_wire;
        if(|int_data_wire)
        begin
          int_case_next = 1'b1;
        end
      end
      1:
      begin
        int_cntr_next = int_cntr_reg + 1'b1;
        int_data_next = int_data_reg | int_data_wire;
        if(&int_cntr_reg)
        begin
          int_case_next = 1'b0;
        end
      end
    endcase
  end

  assign test_data = {|int_data_reg[63:48], |int_data_reg[47:32]};

endmodule
