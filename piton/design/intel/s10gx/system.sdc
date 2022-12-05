##########################################################################
################################ Clocks ##################################
##########################################################################

create_clock -period 20 [get_ports chipset_clk_osc]
#set_clock_groups -asynchronous -group [get_clocks {chipset_clk_osc}]

#set_false_path -from [get_ports sys_rst_n] -to *
