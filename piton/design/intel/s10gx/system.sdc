##########################################################################
################################ Clocks ##################################
##########################################################################

create_clock -period 20 [get_ports chipset_clk_osc]
#set_clock_groups -asynchronous -group [get_clocks {chipset_clk_osc}]

#set_false_path -from [get_ports sys_rst_n] -to *

#set_false_path -from * -to [get_ports leds[0]]
#set_false_path -from * -to [get_ports leds[1]]
#set_false_path -from * -to [get_ports leds[2]]
#set_false_path -from * -to [get_ports leds[3]]
#set_false_path -from * -to [get_ports leds[4]]
#set_false_path -from * -to [get_ports leds[5]]
#set_false_path -from * -to [get_ports leds[6]]
#set_false_path -from * -to [get_ports leds[7]]

#set_false_path -from [get_ports sw[0]] -to *
#set_false_path -from [get_ports sw[1]] -to *
#set_false_path -from [get_ports sw[2]] -to *
#set_false_path -from [get_ports sw[3]] -to *

#set_false_path -from * -to [get_ports uart_tx]

#if { ![info exists OVERRIDE_GLOBALS] || !$OVERRIDE_GLOBALS } {
#    set INPUT_DELAY_FACTOR 0.3
#    set OUTPUT_DELAY_FACTOR 0.3
#    set CPU_JTAG_CLK_PERIOD 20
#}
