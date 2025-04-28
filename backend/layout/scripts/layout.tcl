
#-----------------------------------------------------------------------------
# Initial configurations
#-----------------------------------------------------------------------------
# see file ${PROJECT_DIR}/backend/synthesis/scripts/run_first.tcl

#-----------------------------------------------------------------------------
# (!) same as $DESIGNS.tcl (!) Main Custom Variables Design Dependent (set local)
#-----------------------------------------------------------------------------
set TECH_DIR $env(TECH_DIR)
set TECH_DIR_GSC $env(TECH_DIR_GSC)
set TECH_DIR_GPDK $env(TECH_DIR_GPDK)
set PROJECT_DIR $env(PROJECT_DIR)
set DESIGNS $env(DESIGNS)
set HDL_NAME $env(HDL_NAME)
set VLOG_LIST $env(VLOG_LIST)
set INTERCONNECT_MODE ple

#-----------------------------------------------------------------------------
# (!) same as $DESIGNS.tcl (!) MAIN Custom Variables to be used in SDC (constraints file)
#-----------------------------------------------------------------------------
set MAIN_CLOCK_NAME clk
set MAIN_RST_NAME rst_n
set BEST_LIB_OPERATING_CONDITION PVT_1P32V_0C
set WORST_LIB_OPERATING_CONDITION PVT_0P9V_125C
set period_clk $env(period_clk)  ;# (100 ns = 10 MHz) (10 ns = 100 MHz) (2 ns = 500 MHz) (1 ns = 1 GHz)
set clk_uncertainty 0.044 ;# ns (a guess)
set clk_latency 0.105 ;# ns (a guess)
set in_delay 0.28 ;# ns
set out_delay 0.35;#ns 
set out_load 0.045 ;#pF 
set slew "146 164 264 252" ;#minimum rise, minimum fall, maximum rise and maximum fall 
set slew_min_rise 0.146 ;# ns
set slew_min_fall 0.164 ;# ns
set slew_max_rise 0.264 ;# ns
set slew_max_fall 0.252 ;# ns
set NET_ZERO VSS ;# power net: see the lef file
set NET_ONE VDD ;# power net: see the lef file

#-----------------------------------------------------------------------------
# Load Path File
#-----------------------------------------------------------------------------
source ${PROJECT_DIR}/backend/synthesis/scripts/common/path.tcl


#-----------------------------------------------------------------------------
# set tech files to be used in ".globals" and ".view"
#-----------------------------------------------------------------------------
set WORST_LIST ${LIB_DIR}/slow_vdd1v0_basicCells.lib
set BEST_LIST ${LIB_DIR}/fast_vdd1v2_basicCells.lib 
set LEF_INIT "${TECH_DIR_GSC}/lef/gsclib045_tech.lef ${TECH_DIR_GSC}/lef/gsclib045_macro.lef";# ${TECH_DIR}/giolib045_v3.3/lef/giolib045.lef"
set CAP_MAX ${TECH_DIR_GPDK}/soce/gpdk045.basic.CapTbl
set CAP_MIN ${TECH_DIR_GPDK}/soce/gpdk045.basic.CapTbl
set QRC_LIST ${TECH_DIR_GPDK}/qrc/rcworst/qrcTechFile


#-----------------------------------------------------------------------------
# Initiates the design files (netlist, LEFs, timing libraries)
#-----------------------------------------------------------------------------
set_db init_power_nets $NET_ONE
set_db init_ground_nets $NET_ZERO
read_mmmc ${LAYOUT_DIR}/scripts/view.view
read_physical -lef $LEF_INIT
read_netlist ../../synthesis/deliverables/${DESIGNS}_${period_clk}ns.v
init_design
connect_global_net $NET_ONE -type pg_pin -pin_base_name $NET_ONE -inst_base_name *
connect_global_net $NET_ZERO -type pg_pin -pin_base_name $NET_ZERO -inst_base_name *

#-----------------------------------------------------------------------------
# Tells Innovus the technology being used
#-----------------------------------------------------------------------------
set_db design_process_node 45

#-----------------------------------------------------------------------------
# Specify floorplan
#-----------------------------------------------------------------------------
# graphical or command
create_floorplan -core_margins_by die -site CoreSite -core_density_size 1 0.7 2.5 2.5 2.5 2.5

#-----------------------------------------------------------------------------
# Add ring (Power planning) 
#-----------------------------------------------------------------------------
# graphical or command
set_db add_rings_skip_shared_inner_ring none
set_db add_rings_avoid_short 1
set_db add_rings_ignore_rows 0
set_db add_rings_extend_over_row 0
add_rings -type core_rings -jog_distance 0.6 -threshold 0.6 -nets "$NET_ONE $NET_ZERO" -follow core -layer {bottom Metal11 top Metal11 right Metal10 left Metal10} -width 0.7 -spacing 0.4 -offset 0.6

#-----------------------------------------------------------------------------
# Add stripes (Power planning) 
#-----------------------------------------------------------------------------
# graphical or command
add_stripes -block_ring_top_layer_limit Metal11 -max_same_layer_jog_length 0.44 -pad_core_ring_bottom_layer_limit Metal9 -set_to_set_distance 7 -pad_core_ring_top_layer_limit Metal11 -spacing 0.4 -layer Metal10 -block_ring_bottom_layer_limit Metal9 -width 0.22 -start_offset 1 -nets "$NET_ONE $NET_ZERO"

#-----------------------------------------------------------------------------
# Sroute
#-----------------------------------------------------------------------------
# graphical or command
route_special -connect core_pin -layer_change_range { Metal1(1) Metal11(11) } -block_pin_target nearest_target -core_pin_target first_after_row_end -allow_jogging 1 -crossover_via_layer_range { Metal1(1) Metal11(11) } -nets "$NET_ONE $NET_ZERO" -allow_layer_change 1 -target_via_layer_range { Metal1(1) Metal11(11) }

#-----------------------------------------------------------------------------
# Save Design: 01_power.enc
#-----------------------------------------------------------------------------
# graphical or command
write_db 01_power.enc


#-----------------------------------------------------------------------------
# Placement
#-----------------------------------------------------------------------------
# graphical or command
set_db place_global_place_io_pins 1
set_db place_global_reorder_scan 0
place_design


#-----------------------------------------------------------------------------
# Save Design: 02_placement.enc
#-----------------------------------------------------------------------------
# graphical or command
write_db 02_placement.enc


#-----------------------------------------------------------------------------
# Extract RC
#-----------------------------------------------------------------------------
# graphical or command
set_db extract_rc_engine pre_route
extract_rc ;# generates RC database for timing analysis and signal integrity (SI) anaysis


#-----------------------------------------------------------------------------
# preCTS optimization
#-----------------------------------------------------------------------------
#set_db opt_drv_fix_max_cap true ; set_db opt_drv_fix_max_tran true ; set_db opt_fix_fanout_load false
#opt_design -pre_cts


#-----------------------------------------------------------------------------
# Pre-CTS timing verification
#-----------------------------------------------------------------------------
set_db timing_analysis_type best_case_worst_case
time_design -pre_cts


#-----------------------------------------------------------------------------
# CTS - Clock Concurrent Optimization Flow
#-----------------------------------------------------------------------------
get_db clock_trees
source ../scripts/cts.ccopt
create_clock_tree_spec -out_file ../scripts/cts.spec ;# creates a database cts spec
get_db clock_trees
ccopt_design ;# creates the clock tree
#delete_clock_tree_spec ;# removes the already loaded cts specification (reset_cts_config)
# look for "CTS constraint violations" in the innovus.log file
# GUI: Viewing clock tree results in the physical view
# select Clock -> CCOpt Clock Tree Debugger -> click OK for default selection in the window


#-----------------------------------------------------------------------------
# Post-CTS timing verification
#-----------------------------------------------------------------------------
set_db timing_analysis_type best_case_worst_case
set_db timing_analysis_clock_propagation_mode sdc_control
time_design -post_cts
time_design -post_cts -hold

#-----------------------------------------------------------------------------
# postCTS optimization
#-----------------------------------------------------------------------------
#opt_design -post_cts ;# optimize for setup
#opt_design -post_cts ;# optimize for hold


#-----------------------------------------------------------------------------
# Save Design: 03_cts.enc
#-----------------------------------------------------------------------------
# graphical or command
write_db 03_cts.enc


#-----------------------------------------------------------------------------
# Routing
#-----------------------------------------------------------------------------
# graphical or command
route_design

#-----------------------------------------------------------------------------
# Post-route timing verification
#-----------------------------------------------------------------------------
set_db timing_analysis_type ocv
time_design -post_route

set_interactive_constraint_modes {normal_genus_slow_max} ;# mode name define in ".view" configuration file
set_propagated_clock [all_clocks] 

set_db timing_analysis_check_type setup
report_timing

set_db timing_analysis_check_type hold
report_timing


#-----------------------------------------------------------------------------
# Save Design: 04_route.enc
#-----------------------------------------------------------------------------
# graphical or command
write_db 04_route.enc


#-----------------------------------------------------------------------------
# Filler Cells Insertion
#-----------------------------------------------------------------------------
# graphical or command
add_fillers -base_cells {FILL8 FILL64 FILL4 FILL32 FILL2 FILL16 FILL1}


#-----------------------------------------------------------------------------
# Save Design: 05_filler.enc
#-----------------------------------------------------------------------------
# graphical or command
write_db 05_filler.enc



#-----------------------------------------------------------------------------
# Fix DRC violations after routing (some commands maybe optional)
#-----------------------------------------------------------------------------
# graphical or command
check_drc
delete_routes -regular_wire_with_drc ;# command to delete routed nets with DRC violations
route_design ;# re-route the design
check_drc ;# check DRC violations again
#
route_eco -fix_drc ;# tries to fix remaining violation nets
check_drc ;# check DRC violations again
# GUI: if there are still violations, open the violation browser to analyze the DRC violation in detail
# manually select and delete the nets or vias that have DRC violations and run route_eco again
route_eco -route_only_layers 2:6;# route_only_layers option restricts eco routing to specified layer range 
check_drc ;# check DRC violations again
# Similarly fix the remaining DRC violations further


#-----------------------------------------------------------------------------
# Save Design: 06_drc.enc
#-----------------------------------------------------------------------------
# graphical or command
write_db 06_drc.enc


#-----------------------------------------------------------------------------
# Write verilog
#-----------------------------------------------------------------------------
write_netlist ../deliverables/${DESIGNS}_layout_${period_clk}ns.v


#-----------------------------------------------------------------------------
# Write SDF
#-----------------------------------------------------------------------------
write_sdf -edge check_edge -map_setuphold merge_always -map_recrem merge_always -version 3.0  ../deliverables/${DESIGNS}_${period_clk}ns_layout.sdf


#-----------------------------------------------------------------------------
# Simulate design and generate VDC file(s)
#-----------------------------------------------------------------------------
# Xcelium: gate level simulation with SDF
# Xcelium: need to create VCD files before use them in the power analysis


#-----------------------------------------------------------------------------
# Power Analysis
#-----------------------------------------------------------------------------
# command
get_db power_method ;# this command should return "static"
report_power -power_unit uW > ../reports/power_report_no_VCD_${period_clk}ns.rpt
#
set_db power_corner min
##set_default_switching_activity -reset
##set_default_switching_activity -input_activity 0.2 -period 100.0 ;# 100 = 10 Mhz
#set_db power_report_missing_nets true
#set_db power_method event_based
#
if {0} {
read_activity_file -format VCD -scope ${DESIGNS}_tb(verification)/DUV ../../../frontend/${DESIGNS}_layout_10kns.vcd
report_power -power_unit uW > ../reports/power_report_VCD_10kns.rpt
#
read_activity_file -format VCD -scope ${DESIGNS}_tb(verification)/DUV ../../../frontend/${DESIGNS}_layout_5kns.vcd -reset
report_power -power_unit uW > ../reports/power_report_VCD_5kns.rpt
#
read_activity_file -format VCD -scope ${DESIGNS}_tb(verification)/DUV ../../../frontend/${DESIGNS}_layout_10kns_minimum.vcd -reset
report_power -power_unit uW > ../reports/power_report_VCD_10kns_minimum.rpt
#
read_activity_file -format VCD -scope ${DESIGNS}_tb(verification)/DUV ../../../frontend/${DESIGNS}_layout_5kns_minimum.vcd -reset
report_power -power_unit uW > ../reports/power_report_VCD_5kns_minimum.rpt
}

read_activity_file -format VCD -scope ${DESIGNS}_tb/U1 ../../../frontend/deliverables/${DESIGNS}_${period_clk}ns_rtl_MIN.vcd
report_power -power_unit uW > ../reports/power_report_VCD_${period_clk}ns_MIN.rpt
#
read_activity_file -format VCD -scope ${DESIGNS}_tb/U1 ../../../frontend/deliverables/${DESIGNS}_${period_clk}ns_rtl_MAX.vcd -reset
report_power -power_unit uW > ../reports/power_report_VCD_${period_clk}ns_MAX.rpt
#


#-----------------------------------------------------------------------------
# Add metal fill
#-----------------------------------------------------------------------------
# graphical or command
add_metal_fill -layers {Metal1 Metal2 Metal3 Metal4 Metal5 Metal6 Metal7 Metal8 Metal9 Metal10 Metal11} ;#-nets {VDD VSS}



#-----------------------------------------------------------------------------
# Write GDS
#-----------------------------------------------------------------------------
write_stream -mode ALL -unit 2000 ../deliverables/${DESIGNS}_${period_clk}ns.gsd
ls streamOut.map ;# this file should be created after write_stream command run


#-----------------------------------------------------------------------------
# Write DEF
#-----------------------------------------------------------------------------
write_def ../deliverables/${DESIGNS}_layout_${period_clk}ns.def


#-----------------------------------------------------------------------------
# Reports
#-----------------------------------------------------------------------------
report_area > ../reports/area_report_${period_clk}ns.rpt
report_timing -from a_i[0] -to underflow_o > ../reports/timing_report_${period_clk}ns.rpt

#-----------------------------------------------------------------------------
# Save Design: 07_to-drc-lvs.enc
#-----------------------------------------------------------------------------
# graphical or command
write_db 07_to-drc-lvs.enc


#-----------------------------------------------------------------------------
# DRC and LVS
#-----------------------------------------------------------------------------
# Virtuoso

gui_show

