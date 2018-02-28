set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

### System controller support logic

set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_K16]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_K19]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_K20]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_L16]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_M15]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_N15]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_N22]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_P16]
set_property IOSTANDARD LVCMOS18 [get_ports PL_pin_P22]

set_property PACKAGE_PIN K16 [get_ports PL_pin_K16]
set_property PACKAGE_PIN K19 [get_ports PL_pin_K19]
set_property PACKAGE_PIN K20 [get_ports PL_pin_K20]
set_property PACKAGE_PIN L16 [get_ports PL_pin_L16]
set_property PACKAGE_PIN M15 [get_ports PL_pin_M15]
set_property PACKAGE_PIN N15 [get_ports PL_pin_N15]
set_property PACKAGE_PIN N22 [get_ports PL_pin_N22]
set_property PACKAGE_PIN P16 [get_ports PL_pin_P16]
set_property PACKAGE_PIN P22 [get_ports PL_pin_P22]

### LED

set_property IOSTANDARD LVCMOS18 [get_ports {led_o[*]}]
set_property SLEW SLOW [get_ports {led_o[*]}]
set_property DRIVE 4 [get_ports {led_o[*]}]

set_property PACKAGE_PIN R7 [get_ports {led_o[0]}]
set_property PACKAGE_PIN U7 [get_ports {led_o[1]}]

### DATA

set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports {data_p_i[*]}]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports {data_n_i[*]}]

set_property PACKAGE_PIN E16 [get_ports {data_n_i[0]}]
set_property PACKAGE_PIN F16 [get_ports {data_p_i[0]}]

set_property PACKAGE_PIN F17 [get_ports {data_n_i[1]}]
set_property PACKAGE_PIN G17 [get_ports {data_p_i[1]}]

set_property PACKAGE_PIN H20 [get_ports {data_n_i[2]}]
set_property PACKAGE_PIN H19 [get_ports {data_p_i[2]}]

set_property PACKAGE_PIN C19 [get_ports {data_n_i[3]}]
set_property PACKAGE_PIN D18 [get_ports {data_p_i[3]}]

set_property PACKAGE_PIN C20 [get_ports {data_n_i[4]}]
set_property PACKAGE_PIN D20 [get_ports {data_p_i[4]}]

set_property PACKAGE_PIN C18 [get_ports {data_n_i[5]}]
set_property PACKAGE_PIN C17 [get_ports {data_p_i[5]}]

set_property PACKAGE_PIN B20 [get_ports {data_n_i[6]}]
set_property PACKAGE_PIN B19 [get_ports {data_p_i[6]}]

set_property PACKAGE_PIN B17 [get_ports {data_n_i[7]}]
set_property PACKAGE_PIN B16 [get_ports {data_p_i[7]}]

set_property PACKAGE_PIN D21 [get_ports {data_n_i[8]}]
set_property PACKAGE_PIN E21 [get_ports {data_p_i[8]}]

set_property PACKAGE_PIN B15 [get_ports {data_n_i[9]}]
set_property PACKAGE_PIN C15 [get_ports {data_p_i[9]}]

set_property PACKAGE_PIN A17 [get_ports {data_n_i[10]}]
set_property PACKAGE_PIN A16 [get_ports {data_p_i[10]}]

set_property PACKAGE_PIN A19 [get_ports {data_n_i[11]}]
set_property PACKAGE_PIN A18 [get_ports {data_p_i[11]}]

set_property PACKAGE_PIN M17 [get_ports {data_n_i[12]}]
set_property PACKAGE_PIN L17 [get_ports {data_p_i[12]}]

set_property PACKAGE_PIN L19 [get_ports {data_n_i[13]}]
set_property PACKAGE_PIN L18 [get_ports {data_p_i[13]}]

set_property PACKAGE_PIN K18 [get_ports {data_n_i[14]}]
set_property PACKAGE_PIN J18 [get_ports {data_p_i[14]}]

set_property PACKAGE_PIN N18 [get_ports {data_n_i[15]}]
set_property PACKAGE_PIN N17 [get_ports {data_p_i[15]}]

set_property PACKAGE_PIN D15 [get_ports {data_n_i[16]}]
set_property PACKAGE_PIN E15 [get_ports {data_p_i[16]}]

set_property PACKAGE_PIN E18 [get_ports {data_n_i[17]}]
set_property PACKAGE_PIN F18 [get_ports {data_p_i[17]}]

set_property PACKAGE_PIN F19 [get_ports {data_n_i[18]}]
set_property PACKAGE_PIN G19 [get_ports {data_p_i[18]}]

set_property PACKAGE_PIN F22 [get_ports {data_n_i[19]}]
set_property PACKAGE_PIN F21 [get_ports {data_p_i[19]}]

set_property PACKAGE_PIN G16 [get_ports {data_n_i[20]}]
set_property PACKAGE_PIN G15 [get_ports {data_p_i[20]}]

set_property PACKAGE_PIN E20 [get_ports {data_n_i[21]}]
set_property PACKAGE_PIN E19 [get_ports {data_p_i[21]}]

set_property PACKAGE_PIN D17 [get_ports {data_n_i[22]}]
set_property PACKAGE_PIN D16 [get_ports {data_p_i[22]}]

set_property PACKAGE_PIN G21 [get_ports {data_n_i[23]}]
set_property PACKAGE_PIN G20 [get_ports {data_p_i[23]}]

set_property PACKAGE_PIN A22 [get_ports {data_n_i[24]}]
set_property PACKAGE_PIN A21 [get_ports {data_p_i[24]}]

set_property PACKAGE_PIN B22 [get_ports {data_n_i[25]}]
set_property PACKAGE_PIN B21 [get_ports {data_p_i[25]}]

set_property PACKAGE_PIN G22 [get_ports {data_n_i[26]}]
set_property PACKAGE_PIN H22 [get_ports {data_p_i[26]}]

set_property PACKAGE_PIN T19 [get_ports {data_n_i[27]}]
set_property PACKAGE_PIN R19 [get_ports {data_p_i[27]}]

set_property PACKAGE_PIN K15 [get_ports {data_n_i[28]}]
set_property PACKAGE_PIN J15 [get_ports {data_p_i[28]}]

set_property PACKAGE_PIN K21 [get_ports {data_n_i[29]}]
set_property PACKAGE_PIN J20 [get_ports {data_p_i[29]}]

set_property PACKAGE_PIN P18 [get_ports {data_n_i[30]}]
set_property PACKAGE_PIN P17 [get_ports {data_p_i[30]}]

set_property PACKAGE_PIN T18 [get_ports {data_n_i[31]}]
set_property PACKAGE_PIN R18 [get_ports {data_p_i[31]}]

set_property PACKAGE_PIN AA4 [get_ports {data_n_i[32]}]
set_property PACKAGE_PIN Y4 [get_ports {data_p_i[32]}]

set_property PACKAGE_PIN T6 [get_ports {data_n_i[33]}]
set_property PACKAGE_PIN R6 [get_ports {data_p_i[33]}]

set_property PACKAGE_PIN W5 [get_ports {data_n_i[34]}]
set_property PACKAGE_PIN W6 [get_ports {data_p_i[34]}]

set_property PACKAGE_PIN W7 [get_ports {data_n_i[35]}]
set_property PACKAGE_PIN V7 [get_ports {data_p_i[35]}]

set_property PACKAGE_PIN W8 [get_ports {data_n_i[36]}]
set_property PACKAGE_PIN V8 [get_ports {data_p_i[36]}]

set_property PACKAGE_PIN Y10 [get_ports {data_n_i[37]}]
set_property PACKAGE_PIN Y11 [get_ports {data_p_i[37]}]

set_property PACKAGE_PIN W12 [get_ports {data_n_i[38]}]
set_property PACKAGE_PIN V12 [get_ports {data_p_i[38]}]

set_property PACKAGE_PIN AA6 [get_ports {data_n_i[39]}]
set_property PACKAGE_PIN AA7 [get_ports {data_p_i[39]}]

set_property PACKAGE_PIN Y8 [get_ports {data_n_i[40]}]
set_property PACKAGE_PIN Y9 [get_ports {data_p_i[40]}]

set_property PACKAGE_PIN V9 [get_ports {data_n_i[41]}]
set_property PACKAGE_PIN V10 [get_ports {data_p_i[41]}]

set_property PACKAGE_PIN U9 [get_ports {data_n_i[42]}]
set_property PACKAGE_PIN U10 [get_ports {data_p_i[42]}]

set_property PACKAGE_PIN U11 [get_ports {data_n_i[43]}]
set_property PACKAGE_PIN U12 [get_ports {data_p_i[43]}]

set_property PACKAGE_PIN W18 [get_ports {data_n_i[44]}]
set_property PACKAGE_PIN W17 [get_ports {data_p_i[44]}]

set_property PACKAGE_PIN AA19 [get_ports {data_n_i[45]}]
set_property PACKAGE_PIN Y19 [get_ports {data_p_i[45]}]

set_property PACKAGE_PIN AB21 [get_ports {data_n_i[46]}]
set_property PACKAGE_PIN AA21 [get_ports {data_p_i[46]}]

set_property PACKAGE_PIN AB22 [get_ports {data_n_i[47]}]
set_property PACKAGE_PIN AA22 [get_ports {data_p_i[47]}]

set_property PACKAGE_PIN AA18 [get_ports {data_n_i[48]}]
set_property PACKAGE_PIN Y18 [get_ports {data_p_i[48]}]

set_property PACKAGE_PIN W21 [get_ports {data_n_i[49]}]
set_property PACKAGE_PIN W20 [get_ports {data_p_i[49]}]

set_property PACKAGE_PIN AB17 [get_ports {data_n_i[50]}]
set_property PACKAGE_PIN AA17 [get_ports {data_p_i[50]}]

set_property PACKAGE_PIN Y16 [get_ports {data_n_i[51]}]
set_property PACKAGE_PIN W16 [get_ports {data_p_i[51]}]

set_property PACKAGE_PIN AB16 [get_ports {data_n_i[52]}]
set_property PACKAGE_PIN AA16 [get_ports {data_p_i[52]}]

set_property PACKAGE_PIN AB12 [get_ports {data_n_i[53]}]
set_property PACKAGE_PIN AA12 [get_ports {data_p_i[53]}]

set_property PACKAGE_PIN AB11 [get_ports {data_n_i[54]}]
set_property PACKAGE_PIN AA11 [get_ports {data_p_i[54]}]

set_property PACKAGE_PIN Y5 [get_ports {data_n_i[55]}]
set_property PACKAGE_PIN Y6 [get_ports {data_p_i[55]}]

set_property PACKAGE_PIN AA8 [get_ports {data_n_i[56]}]
set_property PACKAGE_PIN AA9 [get_ports {data_p_i[56]}]

set_property PACKAGE_PIN W10 [get_ports {data_n_i[57]}]
set_property PACKAGE_PIN W11 [get_ports {data_p_i[57]}]

set_property PACKAGE_PIN AB9 [get_ports {data_n_i[58]}]
set_property PACKAGE_PIN AB10 [get_ports {data_p_i[58]}]

set_property PACKAGE_PIN U4 [get_ports {data_n_i[59]}]
set_property PACKAGE_PIN T4 [get_ports {data_p_i[59]}]

set_property PACKAGE_PIN AB6 [get_ports {data_n_i[60]}]
set_property PACKAGE_PIN AB7 [get_ports {data_p_i[60]}]

set_property PACKAGE_PIN U5 [get_ports {data_n_i[61]}]
set_property PACKAGE_PIN U6 [get_ports {data_p_i[61]}]

set_property PACKAGE_PIN AB4 [get_ports {data_n_i[62]}]
set_property PACKAGE_PIN AB5 [get_ports {data_p_i[62]}]

set_property PACKAGE_PIN V4 [get_ports {data_n_i[63]}]
set_property PACKAGE_PIN V5 [get_ports {data_p_i[63]}]
