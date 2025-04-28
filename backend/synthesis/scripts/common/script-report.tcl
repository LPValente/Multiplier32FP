proc get_lp_cells {} {
  global levelShifters
  set levelShifters ""
  global isoCells             
  set isoCells ""
  global clockGateCells  
  set clockGateCells ""
  global srpgCells        
  set srpgCells ""
  foreach lc [get_db lib_cells *] {
    if { [get_db $lc .is_level_shifter] == true } { lappend levelShifters $lc}
    if { [get_db $lc .is_isolation_cell] == true } { lappend isoCells $lc}     
    if { [get_db $lc .clock_gating_integrated_cell] != "" } { 
      lappend clockGateCells $lc
      switch [get_db $lc .clock_gating_integrated_cell] {
        generic { lappend generic $lc }
        latch_posedge { lappend lp $lc }
        latch_posedge_precontrol { lappend lppre $lc }
        latch_posedge_precontrol_obs { lappend lppreo $lc }
        latch_posedge_postcontrol { lappend lppost $lc }
        latch_posedge_postcontrol_obs { lappend lpposto $lc }
        latch_negedge { lappend ln $lc }
        latch_negedge_precontrol { lappend lnpre $lc }
        latch_negedge_precontrol_obs { lappend lnpreo $lc }
        latch_negedge_postcontrol { lappend lnpost $lc }
        latch_negedge_postcontrol_obs { lappend lnposto $lc } 
        ff_posedge { lappend fp $lc }
        ff_posedge_precontrol { lappend fppre $lc }
        ff_posedge_precontrol_obs { lappend fppreo $lc }
        ff_posedge_postcontrol { lappend fppost $lc }
        ff_posedge_postcontrol_obs { lappend fpposto $lc }
        ff_negedge { lappend fn $lc }
        ff_negedge_precontrol { lappend fnpre $lc }
        ff_negedge_precontrol_obs { lappend fnpreo $lc }
        ff_negedge_postcontrol { lappend fnpost $lc }
        ff_negedge_postcontrol_obs { lappend fnposto $lc }
        none_posedge { lappend np $lc }
        none_posedge_control { lappend npc $lc }
        none_posedge_control_obs { lappend npco $lc }
        none_negedge { lappend nn $lc }
        none_negedge_control { lappend nnc $lc }
        none_negedge_control_obs { lappend nnco $lc }
      }
    }
    if { [get_db $lc .power_gating_cell] == true } { lappend srpgCells $lc}  
  }

  puts "[llength $levelShifters] cells are identified as level shifters\n"
  puts "[llength $isoCells] cells are identified as pure isolation cells\n"     
  puts "[llength $clockGateCells] cells are identified as integrated clock gating cells:"
  if { [info exist lp] } { puts "    [llength $lp] of those use latch-based logic for posedge-triggered regs, without test-control" } 
  if { [info exist lppre] } { puts "    [llength $lppre] of those use latch-based logic for posedge-triggered registers, with test-control before the latch" }  
  if { [info exist lppreo] } { puts "    [llength $lppreo] of those use latch-based logic for posedge-triggered registers, with observable test-control before the latch" }
  if { [info exist lppost] } { puts "    [llength $lppost] of those use latch-based logic for posedge-triggered registers, with test-control after the latch" }
  if { [info exist lpposto] } { puts "    [llength $lpposto] of those use latch-based logic for posedge-triggered registers, with observable test-control after the latch" }
  if { [info exist ln] } { puts "    [llength $ln] of those use latch-based logic for negedge-triggered registers, without test-control" }
  if { [info exist lnpre] } { puts "    [llength $lnpre] of those use latch-based logic for negedge-triggered registers, with test-control before the latch" }
  if { [info exist lnpreo] } { puts "    [llength $lnpreo] of those use latch-based logic for negedge-triggered registers, with observable test-control before the latch" }
  if { [info exist lnpost] } { puts "    [llength $lnpost] of those use latch-based logic for negedge-triggered registers, with test-control after the latch" }
  if { [info exist lnposto] } { puts "    [llength $lnposto] of those use latch-based logic for negedge-triggered registers, with observable test-control after the latch" }
  if { [info exist fp] } { puts "    [llength $fp] of those use flop-based logic for posedge-triggered regs, without test-control" }
  if { [info exist fppre] } { puts "    [llength $fppre] of those use flop-based logic for posedge-triggered regs, with test-control before the flop" }
  if { [info exist fppreo] } { puts "    [llength $fppreo] of those use flop-based logic for posedge-triggered regs, with observable test-control before the flop" }
  if { [info exist fppost] } { puts "    [llength $fppost] of those use flop-based logic for posedge-triggered regs, with test-control after the flop" }
  if { [info exist fpposto] } { puts "    [llength $fpposto] of those use flop-based logic for posedge-triggered regs, with observable test-control after the flop" }
  if { [info exist fn] } { puts "    [llength $fn] of those use flop-based logic for negedge-triggered regs, without test-control" }
  if { [info exist fnpre] } { puts "    [llength $fnpre] of those use flop-based logic for negedge-triggered regs, with test-control before the flop" }
  if { [info exist fnpreo] } { puts "    [llength $fnpreo] of those use flop-based logic for negedge-triggered regs, with observable test-control before the flop" }
  if { [info exist fnpost] } { puts "    [llength $fnpost] of those use flop-based logic for negedge-triggered regs, with test-control after the flop" }
  if { [info exist fnposto] } { puts "    [llength $fnposto] of those use flop-based logic for negedge-triggered regs, with observable test-control after the flop" }
  if { [info exist np] } { puts "    [llength $np] of those use latch-free logic for posedge-triggered regs, without test-control" }
  if { [info exist npc] } { puts "    [llength $npc] of those use latch-free logic for posedge-triggered regs, with test-control" } 
  if { [info exist npco] } { puts "    [llength $npco] of those use latch-free logic for posedge-triggered regs, with observable test-control" } 
  if { [info exist nn] } { puts "    [llength $nn] of those  use latch-free logic for negedge-triggered regs, without test-control" } 
  if { [info exist nnc] } { puts "    [llength $nnc] of those  use latch-free logic for negedge-triggered regs, with test-control" } 
  if { [info exist nnco] } { puts "    [llength $nnco] of those  use latch-free logic for negedge-triggered regs, with observable test-control" } 
  if { [info exist generic] } { puts "    [llength $generic] of those have their functionality inferred from the Liberty state table" }  
  puts "\n[llength $srpgCells] cells are identified as SRPG cells\n"
}
