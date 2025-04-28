
#-----------------------------------------------------------------------------
# Create Library Domain
#-----------------------------------------------------------------------------
create_library_domain {worst best} 
get_db library_domains *


#-----------------------------------------------------------------------------
# LEF Files and Technology Library
#-----------------------------------------------------------------------------
set_db lib_search_path "${LIB_DIR} ${LEF_DIR}"
set_db [get_db library_domains worst] .library ${WORST_LIST}
set_db [get_db library_domains best] .library ${BEST_LIST}


#-----------------------------------------------------------------------------
# Operating conditions
#-----------------------------------------------------------------------------
get_db [get_db library_domains *worst] .operating_conditions
set_db [get_db library_domains *worst] .operating_conditions ${WORST_LIB_OPERATING_CONDITION}
get_db [get_db library_domains *worst] .operating_conditions
#--
get_db [get_db library_domains *best] .operating_conditions
set_db [get_db library_domains *best] .operating_conditions ${BEST_LIB_OPERATING_CONDITION}
get_db [get_db library_domains *best] .operating_conditions
#--
get_db [get_db library_domain *worst] .default
get_db [get_db library_domain *best] .default 
#--
get_db [vfind /libraries -library_domain worst] .active_operating_conditions
get_db [vfind /libraries -library_domain best] .active_operating_conditions 
#--
#delete_obj [get_db library_domains *best]
#delete_obj [get_db library_domains *worst]



#-----------------------------------------------------------------------------
# LEF, QRC and CAP Files
#-----------------------------------------------------------------------------

# Load lef files
set_db lef_library ${LEF_LIST}


# Load cap table files
#set_db cap_table_file ${WORST_CAP_LIST}


# Load QRC tech files. OBS: Data from existing 'cap_table_file' is overwritten by technology file
set_db qrc_tech_file ${QRC_LIST}


# Use PLE mode
get_db interconnect_mode
set_db interconnect_mode ple ;# global


set DFT $env(DFT)


if { $DFT == "" } {
  set DFT "true"
}



#-----------------------------------------------------------------------------
# Manage Cells
#-----------------------------------------------------------------------------
# Try to save power; gated clock cells
# No scan flip-flops if ".dont_use true"
get_lib_cells
get_db lib_cells *SDFF*
get_db base_cell:SDFFRHQX1 .dont_use
set_db base_cell:SDFFRHQX1 .dont_use $DFT
foreach lc [get_db base_cells -if {.name == "SDFF*"}] {
  get_db $lc .dont_use
  set_db $lc .dont_use $DFT
}


foreach lc [get_db base_cells -if {.name == "TLATS*"}] {
  get_db $lc .dont_use
  set_db $lc .dont_use $DFT
}



#-----------------------------------------------------------------------------
# Report important info
#-----------------------------------------------------------------------------
# To find libraries present in the library domain
get_db [get_db library_sets *worst] .libraries
get_db [get_db library_sets *best] .libraries
# To get all library cells from all the libraries present in the library domain
get_db [get_db library_sets *worst] .libraries.lib_cells
get_db [get_db library_sets *best] .libraries.lib_cells
# To get lib_cells only from a particular library in the library domain
get_db [get_db [get_db library_sets *worst] .libraries *slow_vdd1v0] .lib_cells
get_db [get_db [get_db library_sets *best] .libraries *fast_vdd1v2] .lib_cells 
# To find a particular lib_cell in the library domain 
get_db [get_db library_sets *worst] .libraries.lib_cells -regexp XOR
get_db [get_db library_sets *best] .libraries.lib_cells -regexp XOR
# To know all attributes of a particular lib_cell in a library domain in Common_UI
get_db [get_db [get_db library_sets *worst] .libraries.lib_cells -regexp CLKXOR2X1] .*



