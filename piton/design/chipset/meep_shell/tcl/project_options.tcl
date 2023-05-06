
#########################################################
# This is reached by protosyn when meep.mode is enabled
#########################################################

if { [info exists "::env(MEEP_SHELL)"] } {

	set MEEP_PATH "$MEEP_ROOT/tcl"

	set p_OPconf $MEEP_PATH/openpiton_conf.tcl

        set fd_OPconf [open $p_OPconf "w"]

        puts $fd_OPconf "set ALL_FILES \"$ALL_FILES\""
        puts $fd_OPconf "set ALL_DEFAULT_VERILOG_MACROS \"$ALL_DEFAULT_VERILOG_MACROS\""
        puts $fd_OPconf "set ALL_INCLUDE_FILES \"$ALL_INCLUDE_FILES\""
        puts $fd_OPconf "set ALL_RTL_IMPL_FILES \"$ALL_RTL_IMPL_FILES\""
        puts $fd_OPconf "set ALL_COE_FILES \"$ALL_COE_FILES\""
        puts $fd_OPconf "set ALL_PRJ_IP_FILES \"$ALL_PRJ_IP_FILES\""
        puts $fd_OPconf "set ALL_XCI_IP_FILES \"$ALL_XCI_IP_FILES\""
        puts $fd_OPconf "set ALL_INCLUDE_DIRS \"$ALL_INCLUDE_DIRS\""

        close $fd_OPconf

	puts "INFO: OpenPiton TCL variables saved."

} else {	

############################################################
# This is reached by the MEEP_SHELL flow process
# which shouldn't have the MEEP_SHELL environment variable enabled	
############################################################			
	
set MEEP_PATH ${g_accel_dir}/piton/design/chipset/meep_shell/tcl

puts "INFO: Reading OpenPiton define lists"


########################################################
# Step 1: Read the OpenPiton Files/Directories List
# 	: generated with Protosyn
########################################################

source $MEEP_PATH/openpiton_conf.tcl
source $MEEP_PATH/additional_defines.tcl
set ALL_VERILOG_MACROS [concat ${ALL_DEFAULT_VERILOG_MACROS} ${PROTOSYN_RUNTIME_DEFINES}]

######################################################
# Step 2: Add the files to the project. This leverages
# 	: from what OpenPiton actually does in 
# 	: gen_project.tcl
######################################################


# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Add files
set fileset_obj [get_filesets sources_1]
set files_to_add [list ]
foreach prj_file ${ALL_FILES} {
    if {[file exists $prj_file]} {
	lappend files_to_add $prj_file
    }
}


add_files -norecurse -fileset $fileset_obj $files_to_add

# Set 'sources_1' fileset file properties for local files
foreach inc_file $ALL_INCLUDE_FILES {
    if {[file exists $inc_file]} {
        set file_obj [get_files -of_objects $fileset_obj [list "$inc_file"]]
        set_property "file_type" "Verilog Header" $file_obj
        set_property "is_enabled" "1" $file_obj
        set_property "is_global_include" "1" $file_obj
        set_property "library" "xil_defaultlib" $file_obj
        set_property "path_mode" "RelativeFirst" $file_obj
        set_property "used_in" "synthesis simulation" $file_obj
        set_property "used_in_simulation" "0" $file_obj
        set_property "used_in_synthesis" "1" $file_obj
    }
}



foreach impl_file $ALL_RTL_IMPL_FILES {
    if {[file exists $impl_file]} {
        set file_obj [get_files -of_objects $fileset_obj [list "$impl_file"]]
        if { [file extension $impl_file] == ".sv"} {
          set_property "file_type" "SystemVerilog" $file_obj
        } else {
          set_property "file_type" "Verilog" $file_obj
        }
        set_property "is_enabled" "1" $file_obj
        set_property "is_global_include" "0" $file_obj
        set_property "library" "xil_defaultlib" $file_obj
        set_property "path_mode" "RelativeFirst" $file_obj
        set_property "used_in" "synthesis implementation simulation" $file_obj
        set_property "used_in_implementation" "1" $file_obj
        set_property "used_in_simulation" "0" $file_obj
        set_property "used_in_synthesis" "1" $file_obj

        # Outside the if else tree from above
        if {[file extension $impl_file] == ".vhd"} {
          set_property "file_type" "VHDL" $file_obj
          set_property "library" "xil_defaultlib" $file_obj
          set_property "used_in_simulation" "0" $file_obj
        }
    }
}


foreach coe_file $ALL_COE_FILES {
    if {[file exists $coe_file]} {
        set file_obj [get_files -of_objects $fileset_obj [list "$coe_file"]]
        set_property "is_enabled" "1" $file_obj
        set_property "is_global_include" "0" $file_obj
        set_property "library" "xil_defaultlib" $file_obj
        set_property "path_mode" "RelativeFirst" $file_obj
        set_property "scoped_to_cells" "" $file_obj
        set_property "scoped_to_ref" "" $file_obj
        set_property "used_in" "synthesis simulation" $file_obj
        set_property "used_in_simulation" "0" $file_obj
        set_property "used_in_synthesis" "1" $file_obj
    }
}


foreach prj_ip_file $ALL_PRJ_IP_FILES {
    if {[file exists $prj_ip_file]} {
        set file_obj [get_files -of_objects $fileset_obj [list "$prj_file"]]
        set_property "is_enabled" "1" $file_obj
        set_property "is_global_include" "0" $file_obj
        set_property "library" "xil_defaultlib" $file_obj
        set_property "path_mode" "RelativeFirst" $file_obj
        set_property "scoped_to_cells" "" $file_obj
        set_property "scoped_to_ref" "" $file_obj
        set_property "used_in" "synthesis" $file_obj
        set_property "used_in_synthesis" "1" $file_obj
    }
}


foreach xci_file $ALL_XCI_IP_FILES {
    if {[file exists $xci_file]} {
        set file_obj [get_files -of_objects $fileset_obj [list "$xci_file"]]
        if { ![get_property "is_locked" $file_obj] } {
          set_property "generate_synth_checkpoint" "1" $file_obj
        }
        set_property "is_enabled" "1" $file_obj
        set_property "is_global_include" "0" $file_obj
        set_property "library" "xil_defaultlib" $file_obj
        set_property "path_mode" "RelativeFirst" $file_obj
        set_property "used_in" "synthesis implementation simulation" $file_obj
        set_property "used_in_implementation" "1" $file_obj
        set_property "used_in_simulation" "0" $file_obj
        set_property "used_in_synthesis" "1" $file_obj
    } 
}

set_property "include_dirs" "${ALL_INCLUDE_DIRS}" $fileset_obj
set_property "verilog_define" "${ALL_VERILOG_MACROS}" $fileset_obj

update_compile_order -fileset $fileset_obj

report_ip_status -name ip_status
upgrade_ip [get_ips * ] -log ip_upgrade.log

puts "INFO: OpenPiton tcl options added."

}

