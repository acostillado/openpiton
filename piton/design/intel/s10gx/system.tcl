##########################################################################
############################# Pin Locations ##############################
##########################################################################
#Clock, Reset, GPIO(LED, DIP, PB...)
set_location_assignment PIN_BH33 -to chipset_clk_osc
set_location_assignment PIN_A20 -to sys_rst_n

set_location_assignment PIN_H18 -to sw[0]
set_location_assignment PIN_G18 -to sw[1]
set_location_assignment PIN_H20 -to sw[2]
set_location_assignment PIN_G20 -to sw[3]

set_location_assignment PIN_B19 -to leds[0]
set_location_assignment PIN_E17 -to leds[1]
set_location_assignment PIN_D18 -to leds[2]
set_location_assignment PIN_D19 -to leds[3]
set_location_assignment PIN_B18 -to leds[4]
set_location_assignment PIN_F17 -to leds[5]
set_location_assignment PIN_E18 -to leds[6]
set_location_assignment PIN_E19 -to leds[7]

set_location_assignment PIN_AV13 -to uart_tx
set_location_assignment PIN_BC11 -to uart_rx

##########################################################################
############### Pin IO Standards & Input Termination #####################
##########################################################################
#Clock, Reset, GPIO(LED, DIP, PB...)
set_instance_assignment -name IO_STANDARD "1.8 V" -to chipset_clk_osc -entity system
set_instance_assignment -name IO_STANDARD "1.8 V" -to sys_rst_n -entity system

set_instance_assignment -name IO_STANDARD "1.8 V" -to sw[0]
set_instance_assignment -name IO_STANDARD "1.8 V" -to sw[1]
set_instance_assignment -name IO_STANDARD "1.8 V" -to sw[2]
set_instance_assignment -name IO_STANDARD "1.8 V" -to sw[3]

set_instance_assignment -name IO_STANDARD "1.8 V" -to leds[0]
set_instance_assignment -name IO_STANDARD "1.8 V" -to leds[1]
set_instance_assignment -name IO_STANDARD "1.8 V" -to leds[2]
set_instance_assignment -name IO_STANDARD "1.8 V" -to leds[3]
set_instance_assignment -name IO_STANDARD "1.8 V" -to leds[4]
set_instance_assignment -name IO_STANDARD "1.8 V" -to leds[5]
set_instance_assignment -name IO_STANDARD "1.8 V" -to leds[6]
set_instance_assignment -name IO_STANDARD "1.8 V" -to leds[7]

set_instance_assignment -name IO_STANDARD "1.8 V" -to uart_rx
set_instance_assignment -name IO_STANDARD "1.8 V" -to uart_tx

set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100

set_global_assignment -name USE_PWRMGT_SCL SDM_IO14
set_global_assignment -name USE_PWRMGT_SDA SDM_IO11

set_global_assignment -name PWRMGT_SLAVE_DEVICE0_ADDRESS 4F
set_global_assignment -name PWRMGT_BUS_SPEED_MODE "400 KHZ"
set_global_assignment -name PWRMGT_PAGE_COMMAND_ENABLE ON
set_global_assignment -name AUTO_RESTART_CONFIGURATION OFF
set_global_assignment -name GENERATE_COMPRESSED_SOF ON

set_global_assignment -name POWER_APPLY_THERMAL_MARGIN ADDITIONAL

set_global_assignment -name RESERVE_ALL_UNUSED_PINS_WEAK_PULLUP "AS INPUT TRI-STATED WITH WEAK PULL-UP"
