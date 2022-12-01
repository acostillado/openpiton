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

set_instance_assignment -name IO_STANDARD "1.8 V" -to uart_rx
set_instance_assignment -name IO_STANDARD "1.8 V" -to uart_tx

set_global_assignment -name RESERVE_ALL_UNUSED_PINS_WEAK_PULLUP "AS INPUT TRI-STATED WITH WEAK PULL-UP"
