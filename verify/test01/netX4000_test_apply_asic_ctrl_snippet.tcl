# \file netX4000_test_read_rotary_snippet.tcl 
# \brief Script to test the functionality of the  netX4000 read rotaryswitch snippet
# \author NW

proc read_data32 {addr} {
  set value(0) 0
  mem2array value 32 $addr 1
  return $value(0)
}

proc read_data8 {addr} {
  set value(0) 0
  mem2array value 8 $addr 1
  return $value(0)
}


# \brief Initialise the TCM memory (Tightly-Coupled Memory)
# enable ITCM+DTCM and set reset vector at start of ITCM
# TRM chapter 4.3.13
# 
# MRC    p15,    0,   <Rd>, c9,  c1,  0
# MRC coproc,  op1, <Rd>, CRn, CRm, op2
# -> arm mrc coproc op1 CRn CRm op2
#
# MCR p15,      0, <Rd>, c9,  c1,  0
# MCR coproc, op1, <Rd>, CRn, CRm, op2
# -> arm mcr coproc op1 CRn CRm op2 value
#
# http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.ddi0458c/CHDEFBFI.html

proc netx4000_enable_tcm {} {
  set __ITCM_START_ADDRESS__         0x00000000
  set __DTCM_START_ADDRESS__         0x00020000
  		
  set MSK_CR7_CP15_ITCMRR_Enable     0x00000001
  set SRT_CR7_CP15_ITCMRR_Enable     0
  
  set MSK_CR7_CP15_ITCMRR_Size        0x0000003c
  set SRT_CR7_CP15_ITCMRR_Size        2
  set VAL_CR7_CP15_ITCMRR_Size_128KB  8
  
  set MSK_CR7_CP15_DTCMRR_Enable     0x00000001
  set SRT_CR7_CP15_DTCMRR_Enable     0
  
  set MSK_CR7_CP15_DTCMRR_Size       0x0000003c
  set SRT_CR7_CP15_DTCMRR_Size       2
  set VAL_CR7_CP15_DTCMRR_Size_128KB 8
  
  set ulItcm [expr $__ITCM_START_ADDRESS__  | $MSK_CR7_CP15_ITCMRR_Enable | ( $VAL_CR7_CP15_ITCMRR_Size_128KB << $SRT_CR7_CP15_ITCMRR_Size ) ]
  set ulDtcm [expr $__DTCM_START_ADDRESS__  | $MSK_CR7_CP15_DTCMRR_Enable | ( $VAL_CR7_CP15_DTCMRR_Size_128KB << $SRT_CR7_CP15_DTCMRR_Size ) ]
  
  puts "netx 4000 Enable ITCM/DTCM"
  puts [ format "ulItcm: %08x" $ulItcm ]
  puts [ format "ulDtcm: %08x" $ulDtcm ]
  
  arm mcr 15 0 9 1 1 $ulItcm
  arm mcr 15 0 9 1 0 $ulDtcm
  
  puts "Set reset vector in ITCM"
  mww 0 0xE59FF00C
  mdw 0
}

# Validation function for the snippet
# variable input parameter are the 3 regsiter values
# constant input prameter are the snippet related parameter



proc validate {} {

  # parameter, which varies from test to test
  global Val_asic_ctrl_io_config
  global Val_asic_ctrl_io_config2
  global Val_asic_ctrl_clock_enable

  # constant parameter, which are constant overall test cases
  global snippet_exec_address
	
	global ADR_asic_ctrl_io_config
	global ADR_asic_ctrl_io_config2
	global ADR_asic_ctrl_clock_enable
	

  set RESULT 0

	  mww  0x04000000  $Val_asic_ctrl_io_config
	  mww  0x04000004  $Val_asic_ctrl_io_config2
	  mww  0x04000008  $Val_asic_ctrl_clock_enable
	  
	  # Start snippet
	  echo "Resume $snippet_exec_address"
	  resume $snippet_exec_address
	  wait_halt
	  
	  
	  # Read back modified register values
	  set rd_value_asic_ctrl_io_config [ format "0x%08x" [read_data32 $ADR_asic_ctrl_io_config]]
	  set rd_value_asic_ctrl_io_config2 [ format "0x%08x" [read_data32 $ADR_asic_ctrl_io_config2]]
	  set rd_value_asic_ctrl_clock_enable [ format "0x%08x" [read_data32 $ADR_asic_ctrl_clock_enable]]
		
	  
	  echo ""
	  echo "########"
	  echo "Check the modified asic_ctrl registers"
		echo "Register io_config (addr: $ADR_asic_ctrl_io_config)"
		echo "  expected: $Val_asic_ctrl_io_config"
		echo "  actual:   $rd_value_asic_ctrl_io_config"
		
	  if {$Val_asic_ctrl_io_config != $rd_value_asic_ctrl_io_config} then {
		  echo "FAILED"
			echo " "
			set RESULT -1
		}

		echo "Register io_config2  (addr: $ADR_asic_ctrl_io_config2)"
		echo "  expected: $Val_asic_ctrl_io_config2"
		echo "  actual:   $rd_value_asic_ctrl_io_config2"

	  if {$Val_asic_ctrl_io_config2 != $rd_value_asic_ctrl_io_config2} then {
		  echo "FAILED"
			echo " "
			set RESULT -1
		}

		echo "Register clock_enable  (addr: $ADR_asic_ctrl_clock_enable)"
		echo "  expected: $Val_asic_ctrl_clock_enable"
		echo "  actual:   $rd_value_asic_ctrl_clock_enable"

	  if {$Val_asic_ctrl_clock_enable != [expr $rd_value_asic_ctrl_clock_enable & $Val_asic_ctrl_clock_enable]} then {
		  echo "FAILED"
			echo " "
			set RESULT -1
		}
		
	  echo "########"

    return $RESULT
}








# \brief Init/probe for JTAG interfaces
proc probe {} {
  global SC_CFG_RESULT
  set SC_CFG_RESULT 0
  set RESULT -1

  # Setup the interface.
  interface ftdi
  transport select jtag
  ftdi_device_desc "NXJTAG-USB"
  ftdi_vid_pid 0x1939 0x0023
  adapter_khz 1000
  ftdi_layout_init 0x0308 0x030b
  ftdi_layout_signal nTRST -data 0x0100 -oe 0x0100
  ftdi_layout_signal nSRST -data 0x0200 -oe 0x0200

# #  # Setup the interface.
# #  interface ftdi
# #  transport select jtag
# #  ftdi_device_desc "NXJTAG-4000-USB"
# #  ftdi_vid_pid 0x1939 0x0301
# #  adapter_khz 1000
# #  
# #  ftdi_layout_init 0x1B08 0x1F0B
# #  ftdi_layout_signal nTRST -data 0x0100 -oe 0x0100
# #  ftdi_layout_signal nSRST -data 0x0200 -oe 0x0200
# #  ftdi_layout_signal JSEL1 -data 0x0400 -oe 0x0400
# #  ftdi_layout_signal VODIS -data 0x0800 -oe 0x0800
# #  ftdi_layout_signal VOSWI -data 0x1000 -oe 0x1000



  # Expect a netX4000 scan chain.
  jtag newtap netx4000 dap -expected-id 0x4ba00477 -irlen 4
  jtag configure netx4000.dap -event setup { global SC_CFG_RESULT ; echo {Yay} ; set SC_CFG_RESULT {OK} }
		
  # Expect working SRST and TRST lines.
  reset_config trst_and_srst

  # Try to initialize the JTAG layer.
  if {[ catch {jtag init} ]==0 } {
    if { $SC_CFG_RESULT=={OK} } {
	  target create netx4000.r7 cortex_r4 -chain-position netx4000.dap -coreid 0 -dbgbase 0x80130000
	  netx4000.r7 configure -work-area-phys 0x05080000 -work-area-size 0x4000 -work-area-backup 1
	  netx4000.r7 configure -event reset-assert-post "cortex_r4 dbginit"
	   
      init

      # Try to stop the CPU.
      halt

	  # Enable the tcm
      netx4000_enable_tcm
	  
    # set addresses to ASIC_CTRL registers
	    global ADR_asic_ctrl_io_config   
	    global ADR_asic_ctrl_io_config2  
	    global ADR_asic_ctrl_clock_enable
		  
	    set ADR_asic_ctrl_io_config    0xf4080100
	    set ADR_asic_ctrl_io_config2   0xf4080108
	    set ADR_asic_ctrl_clock_enable 0xf4080138

	  # Set snippet file name, start adress and execution adress
      set filename_snippet_apply_asic_ctrl_netx4000_bin ../../targets/netx4000_cr7_llram/apply_asic_ctrl_netx4000.bin
	    set snippet_load_address 0x04010000
			global snippet_exec_address
      set snippet_exec_address 0x04010000

    # configure
		# -  ARM32bit mode
		# -  supervisor mode
		# -  link register to the breakpoint, so that the return from the main program will stop at the breakpoint
	  # Set breakpoint, Current Program Status Register(cpsr), Stack Pointer and Link Register
      bp 0x04100000 4 hw
      reg cpsr 0xd3
      reg sp_svc 0x0003ffec
      reg lr_svc 0x04100000

    # Download the snippet.
      load_image $filename_snippet_apply_asic_ctrl_netx4000_bin $snippet_load_address bin
		# dump memory area with the image	
			mdb 0x04010000 0x50
	  
	  # Set the handover register r0
	    reg r0 0x04000000 
	  
		# be optimistic
		set RESULT "0"
		
		# test case 1
		
	  # prepare handover values into snippet
		  global Val_asic_ctrl_io_config
      global Val_asic_ctrl_io_config2
      global Val_asic_ctrl_clock_enable

	    set Val_asic_ctrl_io_config       0x00000001
	    set Val_asic_ctrl_io_config2      0x00000002
	    set Val_asic_ctrl_clock_enable    0x00300000
			
		  if {[validate] != "0"} {set RESULT "-1"}

		
	  if {$RESULT == "0"} then {
      echo "  ______    __  ___"
      echo " /  __  \\  |  |/  /"
      echo "|  |  |  | |  '  / "
      echo "|  |  |  | |    <  "
      echo "|  `--'  | |  .  \\ "
      echo " \\______/  |__|\\__\\"
		}
		
		
	  if {$RESULT == "-1"} then {
      echo " _______    ___       __   __       _______  _______   "
      echo "|   ____|  /   \\     |  | |  |     |   ____||       \\  "
      echo "|  |__    /  ^  \\    |  | |  |     |  |__   |  .--.  | "
      echo "|   __|  /  /_\\  \\   |  | |  |     |   __|  |  |  |  | "
      echo "|  |    /  _____  \\  |  | |  `----.|  |____ |  '--'  | "
      echo "|__|   /__/     \\__\\ |__| |_______||_______||_______/  "
			}
			
   }
  }

  return $RESULT
}

probe

shutdown