### System controller support logic

create_bd_port -dir O PL_pin_L16
create_bd_port -dir O PL_pin_N22
create_bd_port -dir I PL_pin_P22

### LED

create_bd_port -dir O -from 1 -to 0 led_o

### LVDS

create_bd_port -dir I -from 63 -to 0 data_p_i
create_bd_port -dir I -from 63 -to 0 data_n_i
