### IIC

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC_1

### LED

create_bd_port -dir O -from 1 -to 0 led_o
