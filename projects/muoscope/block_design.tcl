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
  DIN_WIDTH 64 DIN_FROM 23 DIN_TO 16
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

for {set i 0} {$i <= 3} {incr i} {
  cell pavel-demin:user:port_slicer slice_[expr $i + 4] {
    DIN_WIDTH 64 DIN_FROM [expr 8 * $i + 39] DIN_TO [expr 8 * $i + 32]
  } {
    Din cfg_0/cfg_data
  }

  cell pavel-demin:user:port_slicer data_slice_$i {
    DIN_WIDTH 65 DIN_FROM [expr 16 * $i + 15] DIN_TO [expr 16 * $i]
  } {
    din edge_0/dout
  }

  cell xilinx.com:ip:c_shift_ram delay_$i {
    WIDTH.VALUE_SRC USER
    SHIFTREGTYPE Variable_Length_Lossless
    WIDTH 16
    DEPTH 256
  } {
    A slice_[expr $i + 4]/dout
    D data_slice_$i/dout
    CLK ps_0/FCLK_CLK0
  }
}

# Create xlslice
cell pavel-demin:user:port_slicer data_slice_4 {
  DIN_WIDTH 65 DIN_FROM 64 DIN_TO 64
} {
  din edge_0/dout
}

# Create c_shift_ram
cell xilinx.com:ip:c_shift_ram delay_4 {
  WIDTH.VALUE_SRC USER
  WIDTH 1
  DEPTH 1
} {
  D data_slice_4/dout
  CLK ps_0/FCLK_CLK0
}

# Create xlconcat
cell xilinx.com:ip:xlconcat concat_0 {
  NUM_PORTS 5
  IN0_WIDTH 16
  IN1_WIDTH 16
  IN2_WIDTH 16
  IN3_WIDTH 16
  IN4_WIDTH 1
} {
  In0 delay_0/Q
  In1 delay_1/Q
  In2 delay_2/Q
  In3 delay_3/Q
  In4 delay_4/Q
}

# Create axis_trigger
cell pavel-demin:user:axis_trigger trg_0 {} {
  din concat_0/dout
  test test_o
  aclk ps_0/FCLK_CLK0
  aresetn slice_1/Dout
}

# Create axis_window
cell pavel-demin:user:axis_window win_0 {} {
  cfg slice_3/Dout
  S_AXIS trg_0/M_AXIS
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
  S_AXIS win_0/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn slice_1/Dout
}

# Create fifo_generator
cell xilinx.com:ip:fifo_generator fifo_generator_0 {
  PERFORMANCE_OPTIONS First_Word_Fall_Through
  INPUT_DATA_WIDTH 128
  INPUT_DEPTH 8192
  OUTPUT_DATA_WIDTH 32
  OUTPUT_DEPTH 32768
  READ_DATA_COUNT true
  READ_DATA_COUNT_WIDTH 16
} {
  clk ps_0/FCLK_CLK0
  srst slice_2/Dout
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
