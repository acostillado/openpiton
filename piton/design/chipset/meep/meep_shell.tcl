
################################################################
# This is a generated script based on design: meep_shell
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2020.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source meep_shell_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcu280-fsvh2892-2L-e
   set_property BOARD_PART xilinx.com:au280:part0:1.1 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name meep_shell

# This script was generated for a remote BD. To create a non-remote design,
# change the variable <run_remote_bd_flow> to <0>.

set run_remote_bd_flow 1
if { $run_remote_bd_flow == 1 } {
  # Set the reference directory for source file relative paths (by default 
  # the value is script directory path)
  set origin_dir ./bd

  # Use origin directory path location variable, if specified in the tcl shell
  if { [info exists ::origin_dir_loc] } {
     set origin_dir $::origin_dir_loc
  }

  set str_bd_folder [file normalize ${origin_dir}]
  set str_bd_filepath ${str_bd_folder}/${design_name}/${design_name}.bd

  # Check if remote design exists on disk
  if { [file exists $str_bd_filepath ] == 1 } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2030 -severity "ERROR" "The remote BD file path <$str_bd_filepath> already exists!"}
     common::send_gid_msg -ssname BD::TCL -id 2031 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0>."
     common::send_gid_msg -ssname BD::TCL -id 2032 -severity "INFO" "Also make sure there is no design <$design_name> existing in your current project."

     return 1
  }

  # Check if design exists in memory
  set list_existing_designs [get_bd_designs -quiet $design_name]
  if { $list_existing_designs ne "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2033 -severity "ERROR" "The design <$design_name> already exists in this project! Will not create the remote BD <$design_name> at the folder <$str_bd_folder>."}

     common::send_gid_msg -ssname BD::TCL -id 2034 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0> or please set a different value to variable <design_name>."

     return 1
  }

  # Check if design exists on disk within project
  set list_existing_designs [get_files -quiet */${design_name}.bd]
  if { $list_existing_designs ne "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2035 -severity "ERROR" "The design <$design_name> already exists in this project at location:
    $list_existing_designs"}
     catch {common::send_gid_msg -ssname BD::TCL -id 2036 -severity "ERROR" "Will not create the remote BD <$design_name> at the folder <$str_bd_folder>."}

     common::send_gid_msg -ssname BD::TCL -id 2037 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0> or please set a different value to variable <design_name>."

     return 1
  }

  # Now can create the remote BD
  # NOTE - usage of <-dir> will create <$str_bd_folder/$design_name/$design_name.bd>
  create_bd_design -dir $str_bd_folder $design_name
} else {

  # Create regular design
  if { [catch {create_bd_design $design_name} errmsg] } {
     common::send_gid_msg -ssname BD::TCL -id 2038 -severity "INFO" "Please set a different value to variable <design_name>."

     return 1
  }
}

current_bd_design $design_name

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:ddr4:2.2\
xilinx.com:ip:util_vector_logic:2.0\
xilinx.com:ip:axi_bram_ctrl:4.1\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:hbm:1.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:qdma:4.0\
xilinx.com:ip:rama:1.1\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:system_ila:1.1\
xilinx.com:ip:util_ds_buf:2.1\
xilinx.com:ip:blk_mem_gen:8.4\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set axi4_mm [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 axi4_mm ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {36} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {6} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {256} \
   CONFIG.NUM_READ_THREADS {16} \
   CONFIG.NUM_WRITE_OUTSTANDING {256} \
   CONFIG.NUM_WRITE_THREADS {16} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $axi4_mm
if {[info exists ::env(PROTOSYN_RUNTIME_HBM_FIRST)] && $::env(PROTOSYN_RUNTIME_HBM_FIRST)=="TRUE"} {
set_property -dict [list CONFIG.DATA_WIDTH {256}] [get_bd_intf_ports axi4_mm]
}

  set axi4_sram [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 axi4_sram ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {19} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {6} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $axi4_sram

  set ddr4_sdram_c0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram_c0 ]

  set ddr_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ddr_clk ]

  set pci_express_x16 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_express_x16 ]

  set pcie_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $pcie_refclk


  # Create ports
  set hbm_cattrip [ create_bd_port -dir O -from 0 -to 0 hbm_cattrip ]
  set mem_calib_complete [ create_bd_port -dir O -from 0 -to 0 -type rst mem_calib_complete ]
  set pcie_gpio [ create_bd_port -dir O -from 4 -to 0 pcie_gpio ]
  set pcie_perstn [ create_bd_port -dir I -type rst pcie_perstn ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $pcie_perstn
  set sys_clk [ create_bd_port -dir I -type clk sys_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {axi4_mm:axi4_sram} \
 ] $sys_clk
  set sys_rst [ create_bd_port -dir I -type rst sys_rst ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $sys_rst

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0 ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO_WIDTH {5} \
 ] $axi_gpio_0

  # Create instance: ddr4_0, and set properties
  set ddr4_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4:2.2 ddr4_0 ]
  set_property -dict [ list \
   CONFIG.ADDN_UI_CLKOUT1_FREQ_HZ {100} \
   CONFIG.C0_CLOCK_BOARD_INTERFACE {sysclk0} \
   CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram_c0} \
   CONFIG.RESET_BOARD_INTERFACE {Custom} \
 ] $ddr4_0

  # Create instance: ddr_axi_rst_inv, and set properties
  set ddr_axi_rst_inv [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 ddr_axi_rst_inv ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $ddr_axi_rst_inv

  # Create instance: ext_axi_sram_ctrl, and set properties
  set ext_axi_sram_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 ext_axi_sram_ctrl ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.ECC_TYPE {0} \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $ext_axi_sram_ctrl

  # Create instance: gndx1, and set properties
  set gndx1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 gndx1 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {1} \
 ] $gndx1

  # Create instance: gndx32, and set properties
  set gndx32 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 gndx32 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {32} \
 ] $gndx32

  # Create instance: hbm_0, and set properties
  set hbm_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:hbm:1.0 hbm_0 ]
  set_property -dict [ list \
   CONFIG.USER_APB_EN {false} \
   CONFIG.USER_CLK_SEL_LIST0 {AXI_00_ACLK} \
   CONFIG.USER_CLK_SEL_LIST1 {AXI_16_ACLK} \
   CONFIG.USER_HBM_CP_1 {6} \
   CONFIG.USER_HBM_DENSITY {8GB} \
   CONFIG.USER_HBM_FBDIV_1 {36} \
   CONFIG.USER_HBM_HEX_CP_RES_1 {0x0000A600} \
   CONFIG.USER_HBM_HEX_FBDIV_CLKOUTDIV_1 {0x00000902} \
   CONFIG.USER_HBM_HEX_LOCK_FB_REF_DLY_1 {0x00001f1f} \
   CONFIG.USER_HBM_LOCK_FB_DLY_1 {31} \
   CONFIG.USER_HBM_LOCK_REF_DLY_1 {31} \
   CONFIG.USER_HBM_RES_1 {10} \
   CONFIG.USER_HBM_STACK {2} \
   CONFIG.USER_MC_ENABLE_08 {TRUE} \
   CONFIG.USER_MC_ENABLE_09 {TRUE} \
   CONFIG.USER_MC_ENABLE_10 {TRUE} \
   CONFIG.USER_MC_ENABLE_11 {TRUE} \
   CONFIG.USER_MC_ENABLE_12 {TRUE} \
   CONFIG.USER_MC_ENABLE_13 {TRUE} \
   CONFIG.USER_MC_ENABLE_14 {TRUE} \
   CONFIG.USER_MC_ENABLE_15 {TRUE} \
   CONFIG.USER_MC_ENABLE_APB_01 {TRUE} \
   CONFIG.USER_MEMORY_DISPLAY {8192} \
   CONFIG.USER_PHY_ENABLE_08 {TRUE} \
   CONFIG.USER_PHY_ENABLE_09 {TRUE} \
   CONFIG.USER_PHY_ENABLE_10 {TRUE} \
   CONFIG.USER_PHY_ENABLE_11 {TRUE} \
   CONFIG.USER_PHY_ENABLE_12 {TRUE} \
   CONFIG.USER_PHY_ENABLE_13 {TRUE} \
   CONFIG.USER_PHY_ENABLE_14 {TRUE} \
   CONFIG.USER_PHY_ENABLE_15 {TRUE} \
   CONFIG.USER_SAXI_00 {true} \
   CONFIG.USER_SAXI_01 {false} \
   CONFIG.USER_SAXI_02 {false} \
   CONFIG.USER_SAXI_03 {false} \
   CONFIG.USER_SAXI_04 {false} \
   CONFIG.USER_SAXI_05 {false} \
   CONFIG.USER_SAXI_06 {false} \
   CONFIG.USER_SAXI_07 {false} \
   CONFIG.USER_SAXI_08 {false} \
   CONFIG.USER_SAXI_09 {false} \
   CONFIG.USER_SAXI_10 {false} \
   CONFIG.USER_SAXI_11 {false} \
   CONFIG.USER_SAXI_12 {false} \
   CONFIG.USER_SAXI_13 {false} \
   CONFIG.USER_SAXI_14 {false} \
   CONFIG.USER_SAXI_15 {false} \
   CONFIG.USER_SAXI_16 {false} \
   CONFIG.USER_SAXI_17 {false} \
   CONFIG.USER_SAXI_18 {false} \
   CONFIG.USER_SAXI_19 {false} \
   CONFIG.USER_SAXI_20 {false} \
   CONFIG.USER_SAXI_21 {false} \
   CONFIG.USER_SAXI_22 {false} \
   CONFIG.USER_SAXI_23 {false} \
   CONFIG.USER_SAXI_24 {false} \
   CONFIG.USER_SAXI_25 {false} \
   CONFIG.USER_SAXI_26 {false} \
   CONFIG.USER_SAXI_27 {false} \
   CONFIG.USER_SAXI_28 {false} \
   CONFIG.USER_SAXI_29 {false} \
   CONFIG.USER_SAXI_30 {false} \
   CONFIG.USER_SAXI_31 {false} \
   CONFIG.USER_SWITCH_ENABLE_01 {TRUE} \
 ] $hbm_0
set_property CONFIG.NUM_READ_THREADS  16 [get_bd_intf_pins /hbm_0/SAXI_00]
set_property CONFIG.NUM_WRITE_THREADS 16 [get_bd_intf_pins /hbm_0/SAXI_00]
if {[info exists ::env(PROTOSYN_RUNTIME_HBM_FIRST)] && $::env(PROTOSYN_RUNTIME_HBM_FIRST)=="TRUE"} {
set_property -dict [list CONFIG.USER_SAXI_01 {true}] [get_bd_cells hbm_0]
set_property CONFIG.NUM_READ_THREADS  16 [get_bd_intf_pins /hbm_0/SAXI_01]
set_property CONFIG.NUM_WRITE_THREADS 16 [get_bd_intf_pins /hbm_0/SAXI_01]
}

  # Create instance: hbm_calib_comb, and set properties
  set hbm_calib_comb [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 hbm_calib_comb ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {and} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_andgate.png} \
 ] $hbm_calib_comb

  # Create instance: hbm_cattrip_comb, and set properties
  set hbm_cattrip_comb [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 hbm_cattrip_comb ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {or} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_orgate.png} \
 ] $hbm_cattrip_comb

  # Create instance: int_axi_sram_ctrl, and set properties
  set int_axi_sram_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 int_axi_sram_ctrl ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.ECC_TYPE {0} \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $int_axi_sram_ctrl

  # Create instance: mem_calib_sync, and set properties
  set mem_calib_sync [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 mem_calib_sync ]
  set_property -dict [ list \
   CONFIG.C_AUX_RESET_HIGH {0} \
 ] $mem_calib_sync

  # Create instance: qdma_0, and set properties
  set qdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:qdma:4.0 qdma_0 ]
  set_property -dict [ list \
   CONFIG.MAILBOX_ENABLE {true} \
   CONFIG.PF0_SRIOV_CAP_INITIAL_VF {4} \
   CONFIG.PF1_MSIX_CAP_TABLE_SIZE_qdma {000} \
   CONFIG.PF1_SRIOV_CAP_INITIAL_VF {0} \
   CONFIG.PF1_SRIOV_FIRST_VF_OFFSET {0} \
   CONFIG.PF2_MSIX_CAP_TABLE_SIZE_qdma {000} \
   CONFIG.PF2_SRIOV_CAP_INITIAL_VF {0} \
   CONFIG.PF2_SRIOV_FIRST_VF_OFFSET {0} \
   CONFIG.PF3_MSIX_CAP_TABLE_SIZE_qdma {000} \
   CONFIG.PF3_SRIOV_CAP_INITIAL_VF {0} \
   CONFIG.PF3_SRIOV_FIRST_VF_OFFSET {0} \
   CONFIG.SRIOV_CAP_ENABLE {true} \
   CONFIG.SRIOV_FIRST_VF_OFFSET {4} \
   CONFIG.barlite_mb_pf0 {1} \
   CONFIG.barlite_mb_pf1 {0} \
   CONFIG.barlite_mb_pf2 {0} \
   CONFIG.barlite_mb_pf3 {0} \
   CONFIG.dma_intf_sel_qdma {AXI_MM} \
   CONFIG.en_axi_st_qdma {false} \
   CONFIG.flr_enable {true} \
   CONFIG.mode_selection {Advanced} \
   CONFIG.pcie_blk_locn {PCIE4C_X1Y0} \
   CONFIG.pf0_ari_enabled {true} \
   CONFIG.pf0_bar0_prefetchable_qdma {true} \
   CONFIG.pf0_bar2_prefetchable_qdma {true} \
   CONFIG.pf1_bar0_prefetchable_qdma {true} \
   CONFIG.pf1_bar2_prefetchable_qdma {true} \
   CONFIG.pf1_msix_enabled_qdma {false} \
   CONFIG.pf2_bar0_prefetchable_qdma {true} \
   CONFIG.pf2_bar2_prefetchable_qdma {true} \
   CONFIG.pf2_msix_enabled_qdma {false} \
   CONFIG.pf3_bar0_prefetchable_qdma {true} \
   CONFIG.pf3_bar2_prefetchable_qdma {true} \
   CONFIG.pf3_msix_enabled_qdma {false} \
   CONFIG.select_quad {GTY_Quad_227} \
   CONFIG.testname {mm} \
   CONFIG.tl_pf_enable_reg {1} \
 ] $qdma_0

if {[info exists ::env(PROTOSYN_RUNTIME_HBM_FIRST)] && $::env(PROTOSYN_RUNTIME_HBM_FIRST)=="TRUE"} {
  # Create instance: rama_0, and set properties
  set rama_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:rama:1.1 rama_0 ]
}

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
if {[info exists ::env(PROTOSYN_RUNTIME_HBM_FIRST)] && $::env(PROTOSYN_RUNTIME_HBM_FIRST)=="TRUE"} {
  set_property -dict [ list \
   CONFIG.NUM_CLKS {2} \
   CONFIG.NUM_MI {3} \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_0
} else {
  set_property -dict [ list \
   CONFIG.NUM_CLKS {3} \
   CONFIG.NUM_MI {3} \
   CONFIG.NUM_SI {2} \
 ] $smartconnect_0
}

  # Create instance: sys_rst_inv, and set properties
  set sys_rst_inv [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 sys_rst_inv ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $sys_rst_inv

  # Create instance: system_ila_1, and set properties
  set system_ila_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 system_ila_1 ]
  set_property -dict [ list \
   CONFIG.C_MON_TYPE {NATIVE} \
   CONFIG.C_NUM_OF_PROBES {1} \
   CONFIG.C_PROBE0_TYPE {0} \
 ] $system_ila_1

  # Create instance: util_ds_buf, and set properties
  set util_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 util_ds_buf ]
  set_property -dict [ list \
   CONFIG.DIFF_CLK_IN_BOARD_INTERFACE {pcie_refclk} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $util_ds_buf

  # Create instance: vccx1, and set properties
  set vccx1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 vccx1 ]

  # Create instance: xchng_sram, and set properties
  set xchng_sram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 xchng_sram ]
  set_property -dict [ list \
   CONFIG.Assume_Synchronous_Clk {false} \
   CONFIG.EN_SAFETY_CKT {true} \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Operating_Mode_A {WRITE_FIRST} \
   CONFIG.Operating_Mode_B {WRITE_FIRST} \
   CONFIG.PRIM_type_to_Implement {BRAM} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Use_RSTB_Pin {true} \
 ] $xchng_sram

  # Create interface connections
  connect_bd_intf_net -intf_net C0_SYS_CLK_0_1 [get_bd_intf_ports ddr_clk] [get_bd_intf_pins ddr4_0/C0_SYS_CLK]
  connect_bd_intf_net -intf_net S_AXI_0_1 [get_bd_intf_ports axi4_sram] [get_bd_intf_pins ext_axi_sram_ctrl/S_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins ext_axi_sram_ctrl/BRAM_PORTA] [get_bd_intf_pins xchng_sram/BRAM_PORTA]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_ports ddr4_sdram_c0] [get_bd_intf_pins ddr4_0/C0_DDR4]
  connect_bd_intf_net -intf_net ext_axi_sram_ctrl_BRAM_PORTA [get_bd_intf_pins int_axi_sram_ctrl/BRAM_PORTA] [get_bd_intf_pins xchng_sram/BRAM_PORTB]
  connect_bd_intf_net -intf_net int_connect_M00_AXI [get_bd_intf_pins hbm_0/SAXI_00] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net int_connect_M01_AXI [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI] [get_bd_intf_pins smartconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net int_connect_M02_AXI [get_bd_intf_pins int_axi_sram_ctrl/S_AXI] [get_bd_intf_pins smartconnect_0/M02_AXI]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_ports pcie_refclk] [get_bd_intf_pins util_ds_buf/CLK_IN_D]
  connect_bd_intf_net -intf_net qdma_0_M_AXI [get_bd_intf_pins qdma_0/M_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net qdma_0_M_AXI_LITE [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins qdma_0/M_AXI_LITE]
  connect_bd_intf_net -intf_net qdma_0_pcie_mgt [get_bd_intf_ports pci_express_x16] [get_bd_intf_pins qdma_0/pcie_mgt]
if {[info exists ::env(PROTOSYN_RUNTIME_HBM_FIRST)] && $::env(PROTOSYN_RUNTIME_HBM_FIRST)=="TRUE"} {
  connect_bd_intf_net -intf_net axi4_mm_1 [get_bd_intf_ports axi4_mm] [get_bd_intf_pins rama_0/s_axi]
  connect_bd_intf_net -intf_net rama_0_m_axi [get_bd_intf_pins hbm_0/SAXI_01] [get_bd_intf_pins rama_0/m_axi]
} else {
  connect_bd_intf_net -intf_net axi4_mm_1 [get_bd_intf_ports axi4_mm] [get_bd_intf_pins smartconnect_0/S01_AXI]
}

  # Create port connections
  connect_bd_net -net axi_gpio_0_gpio_io_o [get_bd_ports pcie_gpio] [get_bd_pins axi_gpio_0/gpio_io_o] [get_bd_pins system_ila_1/probe0]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets axi_gpio_0_gpio_io_o]
  connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins hbm_0/HBM_REF_CLK_0] [get_bd_pins hbm_0/HBM_REF_CLK_1]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk [get_bd_pins ddr4_0/c0_ddr4_ui_clk] [get_bd_pins smartconnect_0/aclk1]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk_sync_rst [get_bd_pins ddr4_0/c0_ddr4_ui_clk_sync_rst] [get_bd_pins ddr_axi_rst_inv/Op1]
  connect_bd_net -net ddr4_0_c0_init_calib_complete [get_bd_pins ddr4_0/c0_init_calib_complete] [get_bd_pins mem_calib_sync/ext_reset_in]
  connect_bd_net -net ddr_axi_rst_inv_Res [get_bd_pins ddr4_0/c0_ddr4_aresetn] [get_bd_pins ddr_axi_rst_inv/Res]
  connect_bd_net -net ddr_calib_comb_Res [get_bd_pins hbm_calib_comb/Res] [get_bd_pins mem_calib_sync/aux_reset_in]
  connect_bd_net -net gndx1_dout [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_arvalid] [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_awvalid] [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_bready] [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_rready] [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_wvalid] [get_bd_pins gndx1/dout]
  connect_bd_net -net hbm_0_DRAM_0_STAT_CATTRIP [get_bd_pins hbm_0/DRAM_0_STAT_CATTRIP] [get_bd_pins hbm_cattrip_comb/Op1]
  connect_bd_net -net hbm_0_DRAM_1_STAT_CATTRIP [get_bd_pins hbm_0/DRAM_1_STAT_CATTRIP] [get_bd_pins hbm_cattrip_comb/Op2]
  connect_bd_net -net hbm_0_apb_complete_0 [get_bd_pins hbm_0/apb_complete_0] [get_bd_pins hbm_calib_comb/Op1]
  connect_bd_net -net hbm_0_apb_complete_1 [get_bd_pins hbm_0/apb_complete_1] [get_bd_pins hbm_calib_comb/Op2]
  connect_bd_net -net hbm_cattrip_comb_Res [get_bd_ports hbm_cattrip] [get_bd_pins hbm_cattrip_comb/Res]
  connect_bd_net -net mem_calib_sync_peripheral_aresetn [get_bd_ports mem_calib_complete] [get_bd_pins mem_calib_sync/peripheral_aresetn]
  connect_bd_net -net pcie_perstn_1 [get_bd_ports pcie_perstn] [get_bd_pins qdma_0/soft_reset_n] [get_bd_pins qdma_0/sys_rst_n]
  connect_bd_net -net qdma_0_axi_aclk [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins hbm_0/AXI_00_ACLK] [get_bd_pins int_axi_sram_ctrl/s_axi_aclk] [get_bd_pins qdma_0/axi_aclk] [get_bd_pins smartconnect_0/aclk] [get_bd_pins system_ila_1/clk]
  connect_bd_net -net qdma_0_axi_aresetn [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins hbm_0/AXI_00_ARESET_N] [get_bd_pins int_axi_sram_ctrl/s_axi_aresetn] [get_bd_pins qdma_0/axi_aresetn] [get_bd_pins smartconnect_0/aresetn]
  connect_bd_net -net sys_rst_0_1 [get_bd_ports sys_rst] [get_bd_pins ddr4_0/sys_rst] [get_bd_pins mem_calib_sync/mb_debug_sys_rst] [get_bd_pins sys_rst_inv/Op1]
  connect_bd_net -net util_ds_buf_IBUF_DS_ODIV2 [get_bd_pins qdma_0/sys_clk] [get_bd_pins util_ds_buf/IBUF_DS_ODIV2]
  connect_bd_net -net util_ds_buf_IBUF_OUT [get_bd_pins qdma_0/sys_clk_gt] [get_bd_pins util_ds_buf/IBUF_OUT]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins qdma_0/qsts_out_rdy] [get_bd_pins qdma_0/tm_dsc_sts_rdy] [get_bd_pins vccx1/dout]
if {[info exists ::env(PROTOSYN_RUNTIME_HBM_FIRST)] && $::env(PROTOSYN_RUNTIME_HBM_FIRST)=="TRUE"} {
  connect_bd_net -net gndx32_dout [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_araddr] [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_awaddr] [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_wdata] [get_bd_pins gndx32/dout] [get_bd_pins hbm_0/AXI_00_WDATA_PARITY] [get_bd_pins hbm_0/AXI_01_WDATA_PARITY]
  connect_bd_net -net s_axi_aclk_0_1 [get_bd_ports sys_clk] [get_bd_pins ext_axi_sram_ctrl/s_axi_aclk] [get_bd_pins hbm_0/APB_0_PCLK] [get_bd_pins hbm_0/APB_1_PCLK] [get_bd_pins hbm_0/AXI_01_ACLK] [get_bd_pins mem_calib_sync/slowest_sync_clk] [get_bd_pins rama_0/axi_aclk]
  connect_bd_net -net sys_rst_inv_Res [get_bd_pins ext_axi_sram_ctrl/s_axi_aresetn] [get_bd_pins hbm_0/APB_0_PRESET_N] [get_bd_pins hbm_0/APB_1_PRESET_N] [get_bd_pins hbm_0/AXI_01_ARESET_N] [get_bd_pins mem_calib_sync/dcm_locked] [get_bd_pins rama_0/axi_aresetn] [get_bd_pins sys_rst_inv/Res]
} else {
  connect_bd_net -net gndx32_dout [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_araddr] [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_awaddr] [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_wdata] [get_bd_pins gndx32/dout] [get_bd_pins hbm_0/AXI_00_WDATA_PARITY]
  connect_bd_net -net s_axi_aclk_0_1 [get_bd_ports sys_clk] [get_bd_pins ext_axi_sram_ctrl/s_axi_aclk] [get_bd_pins hbm_0/APB_0_PCLK] [get_bd_pins hbm_0/APB_1_PCLK] [get_bd_pins mem_calib_sync/slowest_sync_clk] [get_bd_pins smartconnect_0/aclk2]
  connect_bd_net -net sys_rst_inv_Res [get_bd_pins ext_axi_sram_ctrl/s_axi_aresetn] [get_bd_pins hbm_0/APB_0_PRESET_N] [get_bd_pins hbm_0/APB_1_PRESET_N] [get_bd_pins mem_calib_sync/dcm_locked] [get_bd_pins sys_rst_inv/Res]
}

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x00000200 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI_LITE] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
if {[info exists ::env(PROTOSYN_RUNTIME_HBM_FIRST)] && $::env(PROTOSYN_RUNTIME_HBM_FIRST)=="TRUE"} {
  assign_bd_address -offset 0x000200000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM00] -force
  assign_bd_address -offset 0x10000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM01] -force
  assign_bd_address -offset 0x20000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM02] -force
  assign_bd_address -offset 0x30000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM03] -force
  assign_bd_address -offset 0x40000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM04] -force
  assign_bd_address -offset 0x50000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM05] -force
  assign_bd_address -offset 0x60000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM06] -force
  assign_bd_address -offset 0x70000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM07] -force
  assign_bd_address -offset 0x80000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM08] -force
  assign_bd_address -offset 0x90000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM09] -force
  assign_bd_address -offset 0xA0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM10] -force
  assign_bd_address -offset 0xB0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM11] -force
  assign_bd_address -offset 0xC0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM12] -force
  assign_bd_address -offset 0xD0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM13] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM14] -force
  assign_bd_address -offset 0xF0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM15] -force
  assign_bd_address -offset 0x000100000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM16] -force
  assign_bd_address -offset 0x000110000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM17] -force
  assign_bd_address -offset 0x000120000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM18] -force
  assign_bd_address -offset 0x000130000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM19] -force
  assign_bd_address -offset 0x000140000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM20] -force
  assign_bd_address -offset 0x000150000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM21] -force
  assign_bd_address -offset 0x000160000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM22] -force
  assign_bd_address -offset 0x000170000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM23] -force
  assign_bd_address -offset 0x000180000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM24] -force
  assign_bd_address -offset 0x000190000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM25] -force
  assign_bd_address -offset 0x0001A0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM26] -force
  assign_bd_address -offset 0x0001B0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM27] -force
  assign_bd_address -offset 0x0001C0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM28] -force
  assign_bd_address -offset 0x0001D0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM29] -force
  assign_bd_address -offset 0x0001E0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM30] -force
  assign_bd_address -offset 0x0001F0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM31] -force
  assign_bd_address -offset 0x00000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM00] -force
  assign_bd_address -offset 0x10000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM01] -force
  assign_bd_address -offset 0x20000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM02] -force
  assign_bd_address -offset 0x30000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM03] -force
  assign_bd_address -offset 0x40000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM04] -force
  assign_bd_address -offset 0x50000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM05] -force
  assign_bd_address -offset 0x60000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM06] -force
  assign_bd_address -offset 0x70000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM07] -force
  assign_bd_address -offset 0x80000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM08] -force
  assign_bd_address -offset 0x90000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM09] -force
  assign_bd_address -offset 0xA0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM10] -force
  assign_bd_address -offset 0xB0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM11] -force
  assign_bd_address -offset 0xC0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM12] -force
  assign_bd_address -offset 0xD0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM13] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM14] -force
  assign_bd_address -offset 0xF0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM15] -force
  assign_bd_address -offset 0x000100000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM16] -force
  assign_bd_address -offset 0x000110000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM17] -force
  assign_bd_address -offset 0x000120000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM18] -force
  assign_bd_address -offset 0x000130000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM19] -force
  assign_bd_address -offset 0x000140000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM20] -force
  assign_bd_address -offset 0x000150000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM21] -force
  assign_bd_address -offset 0x000160000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM22] -force
  assign_bd_address -offset 0x000170000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM23] -force
  assign_bd_address -offset 0x000180000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM24] -force
  assign_bd_address -offset 0x000190000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM25] -force
  assign_bd_address -offset 0x0001A0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM26] -force
  assign_bd_address -offset 0x0001B0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM27] -force
  assign_bd_address -offset 0x0001C0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM28] -force
  assign_bd_address -offset 0x0001D0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM29] -force
  assign_bd_address -offset 0x0001E0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM30] -force
  assign_bd_address -offset 0x0001F0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM31] -force
} else {
  assign_bd_address -offset 0x00000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x000200000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM00] -force
  assign_bd_address -offset 0x000210000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM01] -force
  assign_bd_address -offset 0x000220000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM02] -force
  assign_bd_address -offset 0x000230000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM03] -force
  assign_bd_address -offset 0x000240000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM04] -force
  assign_bd_address -offset 0x000250000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM05] -force
  assign_bd_address -offset 0x000260000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM06] -force
  assign_bd_address -offset 0x000270000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM07] -force
  assign_bd_address -offset 0x000280000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM08] -force
  assign_bd_address -offset 0x000290000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM09] -force
  assign_bd_address -offset 0x0002A0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM10] -force
  assign_bd_address -offset 0x0002B0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM11] -force
  assign_bd_address -offset 0x0002C0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM12] -force
  assign_bd_address -offset 0x0002D0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM13] -force
  assign_bd_address -offset 0x0002E0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM14] -force
  assign_bd_address -offset 0x0002F0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM15] -force
  assign_bd_address -offset 0x000300000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM16] -force
  assign_bd_address -offset 0x000310000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM17] -force
  assign_bd_address -offset 0x000320000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM18] -force
  assign_bd_address -offset 0x000330000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM19] -force
  assign_bd_address -offset 0x000340000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM20] -force
  assign_bd_address -offset 0x000350000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM21] -force
  assign_bd_address -offset 0x000360000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM22] -force
  assign_bd_address -offset 0x000370000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM23] -force
  assign_bd_address -offset 0x000380000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM24] -force
  assign_bd_address -offset 0x000390000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM25] -force
  assign_bd_address -offset 0x0003A0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM26] -force
  assign_bd_address -offset 0x0003B0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM27] -force
  assign_bd_address -offset 0x0003C0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM28] -force
  assign_bd_address -offset 0x0003D0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM29] -force
  assign_bd_address -offset 0x0003E0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM30] -force
  assign_bd_address -offset 0x0003F0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM31] -force
  assign_bd_address -offset 0x00000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x000200000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM00] -force
  assign_bd_address -offset 0x000210000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM01] -force
  assign_bd_address -offset 0x000220000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM02] -force
  assign_bd_address -offset 0x000230000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM03] -force
  assign_bd_address -offset 0x000240000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM04] -force
  assign_bd_address -offset 0x000250000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM05] -force
  assign_bd_address -offset 0x000260000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM06] -force
  assign_bd_address -offset 0x000270000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM07] -force
  assign_bd_address -offset 0x000280000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM08] -force
  assign_bd_address -offset 0x000290000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM09] -force
  assign_bd_address -offset 0x0002A0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM10] -force
  assign_bd_address -offset 0x0002B0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM11] -force
  assign_bd_address -offset 0x0002C0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM12] -force
  assign_bd_address -offset 0x0002D0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM13] -force
  assign_bd_address -offset 0x0002E0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM14] -force
  assign_bd_address -offset 0x0002F0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM15] -force
  assign_bd_address -offset 0x000300000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM16] -force
  assign_bd_address -offset 0x000310000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM17] -force
  assign_bd_address -offset 0x000320000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM18] -force
  assign_bd_address -offset 0x000330000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM19] -force
  assign_bd_address -offset 0x000340000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM20] -force
  assign_bd_address -offset 0x000350000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM21] -force
  assign_bd_address -offset 0x000360000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM22] -force
  assign_bd_address -offset 0x000370000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM23] -force
  assign_bd_address -offset 0x000380000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM24] -force
  assign_bd_address -offset 0x000390000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM25] -force
  assign_bd_address -offset 0x0003A0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM26] -force
  assign_bd_address -offset 0x0003B0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM27] -force
  assign_bd_address -offset 0x0003C0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM28] -force
  assign_bd_address -offset 0x0003D0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM29] -force
  assign_bd_address -offset 0x0003E0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM30] -force
  assign_bd_address -offset 0x0003F0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM31] -force
  assign_bd_address -offset 0x000800000000 -range 0x00080000 -target_address_space [get_bd_addr_spaces axi4_mm] [get_bd_addr_segs int_axi_sram_ctrl/S_AXI/Mem0] -force
}
  assign_bd_address -offset 0x000800000000 -range 0x00080000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI] [get_bd_addr_segs int_axi_sram_ctrl/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00080000 -target_address_space [get_bd_addr_spaces axi4_sram] [get_bd_addr_segs ext_axi_sram_ctrl/S_AXI/Mem0] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


