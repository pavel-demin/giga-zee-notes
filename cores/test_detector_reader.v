
`timescale 1 ns / 1 ps

module test_detector_reader
(
  // System signals
  input  wire        aclk,
  input  wire        aresetn,

  input  wire [65:0] din,
  input  wire [10:0] cfg,

  output wire [1:0]  test
);

  reg [65:0] int_data_reg, int_data_next;
  reg [7:0] int_cntr_reg, int_cntr_next;
  reg int_case_reg, int_case_next;

  always @(posedge aclk)
  begin
    if(~aresetn)
    begin
      int_data_reg <= 66'd0;
      int_cntr_reg <= 8'd0;
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
        int_data_next = din;
        int_cntr_next = 8'd0;
        if(|din)
        begin
          int_case_next = 1'b1;
        end
      end
      1:
      begin
        int_data_next = int_data_reg | din;
        int_cntr_next = int_cntr_reg + 1'b1;
        if(int_cntr_reg >= cfg[7:0])
        begin
          int_case_next = 1'b0;
        end
      end
    endcase
  end

  assign test = {int_data_reg[65], |int_data_reg[15:0]};

endmodule
