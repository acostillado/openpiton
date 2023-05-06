
#########################################################
# This is reached by protosyn when meep.mode is enabled
#########################################################

if { [info exists "::env(MEEP_SHELL)"] } {

	set p_all_files $MEEP_PATH/all_files.meep
	set p_verilog_macros $MEEP_PATH/all_default_verilog_macros.meep
	set p_all_include_files $MEEP_PATH/all_include_files.meep
	set p_all_rtl_impl_files $MEEP_PATH/all_rtl_impl_files.meep
	set p_all_coe_files $MEEP_PATH/all_coe_files.meep
	set p_all_prj_ip_files $MEEP_PATH/all_prj_ip_files.meep
	set p_all_xci_ip_files $MEEP_PATH/all_xci_ip_files.meep
	set p_all_include_dirs $MEEP_PATH/all_include_dirs.meep

        set fd_all_files [open $p_all_files "w"]
        set fd_verilog_macros [open $p_verilog_macros "w"]
        set fd_all_include_files [open $p_all_files "w"]
        set fd_all_rtl_impl_files [open $p_verilog_macros "w"]
        set fd_all_coe_files [open $p_all_files "w"]
        set fd_all_prj_ip_files [open $p_verilog_macros "w"]
        set fd_all_xci_ip_files [open $p_all_files "w"]
        set fd_all_include_dirs [open $p_verilog_macros "w"]

        puts $fd_all_files $ALL_FILES
        puts $fd_verilog_macros $ALL_DEFAULT_VERILOG_MACROS
        puts $fd_all_include_files $ALL_INCLUDE_FILES
        puts $fd_all_rtl_impl_files $ALL_RTL_IMPL_FILES
        puts $fd_all_coe_files $ALL_COE_FILES
        puts $fd_all_prj_ip_files $ALL_PRJ_IP_FILES
        puts $fd_all_xci_ip_files $ALL_XCI_IP_FILES
        puts $fd_all_include_dirs $ALL_INCLUDE_DIRS

        close $fd_all_files
        close $fd_verilog_macros
        close $fd_all_include_files
        close $fd_all_rtl_impl_files
        close $fd_all_coe_files
        close $fd_all_prj_ip_files
        close $fd_all_xci_ip_files
        close $fd_all_include_dirs

} else {	

############################################################
# This is reached by the MEEP_SHELL flow process
# which shouldn't have the MEEP_SHELL environment variable enabled	
############################################################			
	
set MEEP_PATH $ACC_PATH/piton/design/chipset/meep_shell


set p_all_files $MEEP_PATH/all_files.meep
set p_verilog_macros $MEEP_PATH/all_default_verilog_macros.meep
set p_all_include_files $MEEP_PATH/all_include_files.meep
set p_all_rtl_impl_files $MEEP_PATH/all_rtl_impl_files.meep
set p_all_coe_files $MEEP_PATH/all_coe_files.meep
set p_all_prj_ip_files $MEEP_PATH/all_prj_ip_files.meep
set p_all_xci_ip_files $MEEP_PATH/all_xci_ip_files.meep
set p_all_include_dirs $MEEP_PATH/all_include_dirs.meep


########################################################
# Step 1: Read the OpenPiton Files/Directories List
# 	: generated with Protosyn
########################################################


set fd_all_files [open $p_all_files "r"]
set fd_verilog_macros [open $p_verilog_macros "r"]
set fd_all_include_files [open $p_all_files "r"]
set fd_all_rtl_impl_files [open $p_verilog_macros "r"]
set fd_all_coe_files [open $p_all_files "r"]
set fd_all_prj_ip_files [open $p_verilog_macros "r"]
set fd_all_xci_ip_files [open $p_all_files "r"]
set fd_all_include_dirs [open $p_verilog_macros "r"]


set ALL_FILES {}
set ALL_DEFAULT_VERILOG_MACROS
set ALL_INCLUDE_FILES {}
set ALL_RTL_IMPL_FILES {}
set ALL_COE_FILES {}
set ALL_PRJ_IP_FILES {}
set ALL_XCI_IP_FILES {}
set ALL_INCLUDE_DIRS {}


while {[get $fd_all_files line] != -1} {
	lappend ALL_FILES $line
}

close $fd_all_files


while {[get $fd_all_default_verilog_macros line] != -1} {
	lappend ALL_DEFAULT_VERILOG_MACROS $line
}

close $fd_all_default_verilog_macros


while {[get $fd_all_include_files line] != -1} {
	lappend ALL_INCLUDE_FILES $line
}

close $fd_all_include_files



while {[get $fd_all_rtl_impl_files line] != -1} {
	lappend ALL_RTL_IMPL_FILES $line
}

close $fd_all_rtl_impl_files


while {[get $fd_all_coe_files line] != -1} {
	lappend ALL_COE_FILES $line
}

close $fd_all_coe_files


while {[get $fd_all_prj_ip_files line] != -1} {
	lappend ALL_PRJ_IP_FILES $line
}

close $fd_all_prj_ip_files


while {[get $fd_all_xci_ip_files line] != -1} {
	lappend ALL_XCI_IP_FILES $line
}

close $fd_all_xci_ip_files



while {[get $fd_all_include_dirs line] != -1} {
	lappend ALL_INCLUDE_DIRS $line
}

close $fd_all_include_dirs



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
        set_property "used_in_simulation" "1" $file_obj
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
        set_property "used_in_simulation" "1" $file_obj
        set_property "used_in_synthesis" "1" $file_obj

        # Outside the if else tree from above
        if {[file extension $impl_file] == ".vhd"} {
          set_property "file_type" "VHDL" $file_obj
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
        set_property "used_in_simulation" "1" $file_obj
        set_property "used_in_synthesis" "1" $file_obj
    }
}

foreach prj_file $ALL_PRJ_IP_FILES {
    if {[file exists $prj_file]} {
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
        set_property "used_in_simulation" "1" $file_obj
        set_property "used_in_synthesis" "1" $file_obj
    }
}

set_property "include_dirs" "${ALL_INCLUDE_DIRS}" $fileset_obj
set_property "verilog_define" "${ALL_DEFAULT_VERILOG_MACROS}" $fileset_obj

puts "INFO: OpenPiton tcl options added:${PROJECT_NAME}"

}

