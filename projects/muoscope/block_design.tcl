# Create processing_system7
cell xilinx.com:ip:processing_system7 ps_0 {
  PCW_IMPORT_BOARD_PRESET cfg/te0720-1cf.xml
} {
  M_AXI_GP0_ACLK ps_0/FCLK_CLK0
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {
  make_external {FIXED_IO, DDR}
  Master Disable
  Slave Disable
} [get_bd_cells ps_0]

# Create xlconstant
cell xilinx.com:ip:xlconstant const_0

# Create proc_sys_reset
cell xilinx.com:ip:proc_sys_reset rst_0 {} {
  ext_reset_in const_0/dout
}

# System controller support logic

connect_bd_net [get_bd_ports PL_pin_P22] [get_bd_pins ps_0/I2C1_SDA_I]

# Create util_vector_logic
cell xilinx.com:ip:util_vector_logic or_0 {
  C_SIZE 1
  C_OPERATION or
} {
  Op1 ps_0/I2C1_SDA_O
  Op2 ps_0/I2C1_SDA_T
  Res PL_pin_N22
}

# Create util_vector_logic
cell xilinx.com:ip:util_vector_logic or_1 {
  C_SIZE 1
  C_OPERATION or
} {
  Op1 ps_0/I2C1_SCL_O
  Op2 ps_0/I2C1_SCL_T
  Res ps_0/I2C1_SCL_I
  Res PL_pin_L16
}

# LED

# Create c_counter_binary
cell xilinx.com:ip:c_counter_binary cntr_0 {
  Output_Width 32
} {
  CLK ps_0/FCLK_CLK0
}

# Create xlslice
cell pavel-demin:user:port_slicer slice_0 {
  DIN_WIDTH 32 DIN_FROM 26 DIN_TO 26
} {
  Din cntr_0/Q
  Dout led_o
}

# CFG

# Create axi_cfg_register
cell pavel-demin:user:axi_cfg_register cfg_0 {
  CFG_DATA_WIDTH 64
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
}

# Create xlslice
cell pavel-demin:user:port_slicer slice_1 {
  DIN_WIDTH 64 DIN_FROM 0 DIN_TO 0
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell pavel-demin:user:port_slicer slice_2 {
  DIN_WIDTH 64 DIN_FROM 1 DIN_TO 1
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell pavel-demin:user:port_slicer slice_3 {
  DIN_WIDTH 64 DIN_FROM 2 DIN_TO 2
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell pavel-demin:user:port_slicer slice_4 {
  DIN_WIDTH 64 DIN_FROM 31 DIN_TO 16
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell pavel-demin:user:port_slicer slice_5 {
  DIN_WIDTH 64 DIN_FROM 39 DIN_TO 32
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell pavel-demin:user:port_slicer slice_6 {
  DIN_WIDTH 64 DIN_FROM 42 DIN_TO 40
} {
  Din cfg_0/cfg_data
}

# DATA

# Create util_ds_buf
cell xilinx.com:ip:util_ds_buf buf_0 {
  C_SIZE 66
  C_BUF_TYPE IBUFDS
} {
  IBUF_DS_P data_p_i
  IBUF_DS_N data_n_i
}

# Create edge_detector
cell pavel-demin:user:edge_detector edge_0 {} {
  din buf_0/IBUF_OUT
  aclk ps_0/FCLK_CLK0
}

# Create edge_detector
cell pavel-demin:user:delay delay_0 {} {
  din edge_0/dout
  cfg slice_4/Dout
  aclk ps_0/FCLK_CLK0
}

# Create axis_trigger
cell pavel-demin:user:axis_trigger trg_0 {} {
  din delay_0/dout
  test test_o
  aclk ps_0/FCLK_CLK0
  aresetn slice_1/Dout
}

# Create axis_window
cell pavel-demin:user:axis_window win_0 {} {
  cfg slice_5/Dout
  S_AXIS trg_0/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn slice_1/Dout
}

# Create axis_selection
cell pavel-demin:user:axis_selection sel_0 {} {
  cfg slice_6/Dout
  S_AXIS win_0/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn slice_1/Dout
}

# Create axis_subset_converter
cell xilinx.com:ip:axis_subset_converter subset_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 16
  M_TDATA_NUM_BYTES 16
  TDATA_REMAP {tdata[31:0],tdata[63:32],tdata[95:64],tdata[127:96]}
} {
  S_AXIS sel_0/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn slice_1/Dout
}

# Create fifo_generator
cell xilinx.com:ip:fifo_generator fifo_generator_0 {
  PERFORMANCE_OPTIONS First_Word_Fall_Through
  INPUT_DATA_WIDTH 128
  INPUT_DEPTH 512
  OUTPUT_DATA_WIDTH 32
  OUTPUT_DEPTH 2048
  READ_DATA_COUNT true
  READ_DATA_COUNT_WIDTH 12
} {
  clk ps_0/FCLK_CLK0
  srst slice_3/Dout
}

# Create axis_fifo
cell pavel-demin:user:axis_fifo fifo_0 {
  S_AXIS_TDATA_WIDTH 128
  M_AXIS_TDATA_WIDTH 32
} {
  S_AXIS subset_0/M_AXIS
  FIFO_READ fifo_generator_0/FIFO_READ
  FIFO_WRITE fifo_generator_0/FIFO_WRITE
  aclk ps_0/FCLK_CLK0
}

# Create axi_axis_reader
cell pavel-demin:user:axi_axis_reader reader_0 {
  AXI_DATA_WIDTH 32
} {
  S_AXIS fifo_0/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn rst_0/peripheral_aresetn
}

# STS

# Create axi_sts_register
cell pavel-demin:user:axi_sts_register sts_0 {
  STS_DATA_WIDTH 32
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
} {
  sts_data fifo_generator_0/rd_data_count
}

addr 0x40000000 4K sts_0/S_AXI /ps_0/M_AXI_GP0

addr 0x40001000 4K cfg_0/S_AXI /ps_0/M_AXI_GP0

addr 0x40002000 8K reader_0/S_AXI /ps_0/M_AXI_GP0
