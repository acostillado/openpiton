##########################################################################
############################# Pin Locations ##############################
##########################################################################
#Clock, Reset, GPIO(LED, DIP, PB...)
set_location_assignment PIN_BH33 -to chipset_clk
set_location_assignment PIN_A20 -to sys_rst_n

##########################################################################
############### Pin IO Standards & Input Termination #####################
##########################################################################
#Clock, Reset, GPIO(LED, DIP, PB...)
set_instance_assignment -name IO_STANDARD "1.8 V" -to chipset_clk -entity system
set_instance_assignment -name IO_STANDARD "1.8 V" -to sys_rst_n -entity system

