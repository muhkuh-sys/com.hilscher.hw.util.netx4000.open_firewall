# \file netX4000_test_open_firewall_snippet.tcl
# \brief Script to test the functionality of the  netX4000 open_firewall snippet
# \author GDo

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


# read and validate a 32bit value
proc validate_32bit {addr_string addr ref mask} {

  # be optimistic
  set RESULT 0

  # Read back modified register values
  set rd_value [ format "0x%08x" [read_data32 $addr]]

  echo ""
  echo "########"
  echo "Check the modified asic_ctrl registers"
  echo "Register $addr_string (addr: $addr)"
  puts [ format "expected: %08x" $ref ]
  puts [ format "masked:   %08x" $mask ]
  puts [ format "actual:   %08x" $rd_value ]

	  if {$ref != [expr $rd_value & $mask]} then {
		  echo "FAILED"
			echo " "
			set RESULT -1
		}
  return $RESULT
}



# Validation function for the snippet
# constant input parameter are the snippet related parameter
proc validate {} {

  # constant parameter, which are constant overall test cases
  global snippet_exec_address

    # set addresses to ASIC_CTRL registers
	  set ADR_asic_ctrl_netx_version    0xf4080148

	  set ADR_firewall_cfg_netx_ram0    0xf40801b0
	  set ADR_firewall_cfg_netx_ram1    0xf40801b4
	  set ADR_firewall_cfg_netx_ram2    0xf40801b8
	  set ADR_firewall_cfg_netx_ramhs0    0xf40801bc
	  set ADR_firewall_cfg_netx_ramhs1    0xf40801c0
	  set ADR_firewall_cfg_netx_rameth    0xf40801c4
	  set ADR_firewall_cfg_netx_extmem    0xf40801c8
	  set ADR_firewall_cfg_netx_hifmem    0xf40801cc
	  set ADR_firewall_cfg_netx_xc_config    0xf40801d0
	  set ADR_firewall_cfg_netx_reg     0xf40801d4

  set RESULT 0

    # Start snippet
    echo "Resume $snippet_exec_address"
    resume $snippet_exec_address
    wait_halt


     if {[validate_32bit "asic_ctrl_netx_version" $ADR_asic_ctrl_netx_version 0x84524c0b 0xFFffFFff] != 0} then {
      echo "FAILED"
      echo " "
      set RESULT -1
    }
    
     # Read back modified register values    
     if {[validate_32bit "firewall_cfg_netx_ram0" $ADR_firewall_cfg_netx_ram0 0xFF 0xFF] != 0} then {
      echo "FAILED"
      echo " "
      set RESULT -1
    }
    
     if {[validate_32bit "firewall_cfg_netx_ram1" $ADR_firewall_cfg_netx_ram1 0xFF 0xFF] != 0} then {
      echo "FAILED"
      echo " "
      set RESULT -1
    }
    
     if {[validate_32bit "firewall_cfg_netx_ram2" $ADR_firewall_cfg_netx_ram2 0xFF 0xFF] != 0} then {
      echo "FAILED"
      echo " "
      set RESULT -1
    }

     if {[validate_32bit "firewall_cfg_netx_ramhs0" $ADR_firewall_cfg_netx_ramhs0 0xFF 0xFF] != 0} then {
      echo "FAILED"
      echo " "
      set RESULT -1
    }

     if {[validate_32bit "firewall_cfg_netx_ramhs1" $ADR_firewall_cfg_netx_ramhs1 0xFF 0xFF] != 0} then {
      echo "FAILED"
      echo " "
      set RESULT -1
    }

     if {[validate_32bit "firewall_cfg_netx_rameth" $ADR_firewall_cfg_netx_rameth 0xFF 0xFF] != 0} then {
      echo "FAILED"
      echo " "
      set RESULT -1
    }

     if {[validate_32bit "firewall_cfg_netx_extmem" $ADR_firewall_cfg_netx_extmem 0xFF 0xFF] != 0} then {
      echo "FAILED"
      echo " "
      set RESULT -1
    }

     if {[validate_32bit "firewall_cfg_netx_hifmem" $ADR_firewall_cfg_netx_hifmem 0xFF 0xFF] != 0} then {
      echo "FAILED"
      echo " "
      set RESULT -1
    }

     if {[validate_32bit "firewall_cfg_netx_xc_config" $ADR_firewall_cfg_netx_xc_config 0xFF 0xFF] != 0} then {
      echo "FAILED"
      echo " "
      set RESULT -1
    }

     if {[validate_32bit "firewall_cfg_netx_reg" $ADR_firewall_cfg_netx_reg 0xFF 0xFF] != 0} then {
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
	  

	  # Set snippet file name, start adress and execution adress
      set filename_snippet_netx4000_open_firewall_bin ../../targets/netx4000_cr7_llram/open_firewall_netx4000.bin
	  set snippet_load_address 0x04001000
	  global snippet_exec_address
      set snippet_exec_address 0x04001000

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
      load_image $filename_snippet_netx4000_open_firewall_bin $snippet_load_address bin
		# dump memory area with the image	
			mdb $snippet_load_address 0x120

		# be optimistic
		set RESULT "0"
		
		# test case 1

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