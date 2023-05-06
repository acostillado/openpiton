# Copyright 2022 Barcelona Supercomputing Center-Centro Nacional de Supercomputación

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Author: Daniel J.Mazure, BSC-CNS
# Date: 22.02.2022
# Description: 


if { $::argc > 0 } {
 set g_root_dir $::argv
 puts "Root directory is $g_root_dir"
} else { 
 puts "Bad usage: this script needs an argument"
 exit -1
}

proc implementation { g_root_dir } {

	open_checkpoint $g_root_dir/dcp/synthesis.dcp
	opt_design
	place_design
	route_design
	
	file mkdir $g_root_dir/dcp
	write_checkpoint -force $g_root_dir/dcp/implementation.dcp 
}

proc reportImpl { g_root_dir } {


	file delete -force $g_root_dir/reports
	file mkdir $g_root_dir/reports

	report_clocks -file "${g_root_dir}/reports/clock.rpt"
	report_utilization -file "${g_root_dir}/reports/utilization.rpt"
	report_timing_summary -delay_type min_max -report_unconstrained -warn_on_violation -check_timing_verbose -input_pins -routable_nets -file "${g_root_dir}/reports/timing_summary.rpt"
	report_power -file "${g_root_dir}/reports/power.rpt"
	report_drc -file "${g_root_dir}/reports/drc_imp.rpt"
	report_timing -setup -file "${g_root_dir}/reports/timing_setup.rpt"
	report_timing -hold -file "${g_root_dir}/reports/timing_hold.rpt"
}
	
implementation $g_root_dir 
reportImpl $g_root_dir

