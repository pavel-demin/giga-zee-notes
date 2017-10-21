set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

### System controller support logic

set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_P22]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_P16]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_N22]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_N15]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_M15]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_L16]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_K20]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_K19]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_K16]

set_property PACKAGE_PIN K16 [get_ports PL_pin_K16]
set_property PACKAGE_PIN K19 [get_ports PL_pin_K19]
set_property PACKAGE_PIN K20 [get_ports PL_pin_K20]
set_property PACKAGE_PIN L16 [get_ports PL_pin_L16]
set_property PACKAGE_PIN M15 [get_ports PL_pin_M15]
set_property PACKAGE_PIN N15 [get_ports PL_pin_N15]
set_property PACKAGE_PIN N22 [get_ports PL_pin_N22]
set_property PACKAGE_PIN P16 [get_ports PL_pin_P16]
set_property PACKAGE_PIN P22 [get_ports PL_pin_P22]

### IIC

set_property IOSTANDARD LVCMOS18 [get_ports iic_1_scl_io]
set_property IOSTANDARD LVCMOS18 [get_ports iic_1_sda_io]
set_property PULLTYPE PULLUP [get_ports iic_1_scl_io]
set_property PULLTYPE PULLUP [get_ports iic_1_sda_io]

set_property PACKAGE_PIN L16 [get_ports iic_1_scl_io]
set_property PACKAGE_PIN N22 [get_ports iic_1_sda_io]

### LED

set_property IOSTANDARD LVCMOS18 [get_ports {led_o[*]}]
set_property SLEW SLOW [get_ports {led_o[*]}]
set_property DRIVE 4 [get_ports {led_o[*]}]

set_property PACKAGE_PIN R7 [get_ports {led_o[0]}]
set_property PACKAGE_PIN U7 [get_ports {led_o[1]}]
