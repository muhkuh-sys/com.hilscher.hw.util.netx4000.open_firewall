
//-----------------------------------------------------------------------------
.section .boot_rom, "ax"
//-----------------------------------------------------------------------------
    
	.text
	.arm

	.global start


start:

	@ Save the ROM stack position and some additional registers.
	stmfd   sp!, {r0, r1, r2, r3, lr}
	
	
@ =====================================================================
@
@Parameterübergabe Register 0
@
@ =====================================================================
#define Addr_ASIC_CTRL               0xf4080100
#define REL_Addr_io_config           0x00000000  
#define REL_Addr_io_config2			 0x00000008
#define REL_Addr_clock_enable		 0x00000038

#define MSK_NX4000_io_config2_sel_xm10_mii               0x000001c0U
#define SRT_NX4000_io_config2_sel_xm10_mii               6
#define MSK_NX4000_io_config2_sel_xm11_mii               0x00000e00U
#define SRT_NX4000_io_config2_sel_xm11_mii               9


#define REL_Adr_NX4000_asic_ctrl_access_key       0x0000007C

	ldr    r1, =Addr_ASIC_CTRL

	@START IOCONFIG
	
	ldr    r2, [r0, #0] 
	
	@@ Required to open access mode to special protected register
	ldr    r3, [r1, #REL_Adr_NX4000_asic_ctrl_access_key]
	str    r3, [r1, #REL_Adr_NX4000_asic_ctrl_access_key]  

	str    r2, [r1, #REL_Addr_io_config]
	
	@START IOCONFIG2
		
	ldr    r2, [r0, #4] 
	
	
	@ldr    r3, [r1, #REL_Addr_io_config2]
	@AND NOT R3 = R3 and not R4
	@BIC    r3, r3, #MSK_NX4000_io_config2_sel_xm10_mii
	@BIC    r3, r3, #MSK_NX4000_io_config2_sel_xm11_mii
	@orr    r2,r2,r3
	
	
	@@ Required to open access mode to special protected register
	ldr    r3, [r1, #REL_Adr_NX4000_asic_ctrl_access_key]
	str    r3, [r1, #REL_Adr_NX4000_asic_ctrl_access_key]  

	str    r2, [r1, #REL_Addr_io_config2]
	
	@START CLOCK_ENABLE
		
	ldr    r2, [r0, #8] 
	ldr    r3, [r1, #REL_Addr_clock_enable]
	
	orr    r2,r2,r3
	
	
	@@ Required to open access mode to special protected register
	ldr    r3, [r1, #REL_Adr_NX4000_asic_ctrl_access_key]
	str    r3, [r1, #REL_Adr_NX4000_asic_ctrl_access_key]  
	str    r2, [r1, #REL_Addr_clock_enable]
	
	@ Make sure that all write operations have finished.
	dsb

	
	
	@ Restore the ROM stack position.
	ldmfd   sp!, {r0, r1, r2, r3, lr}
	bx      lr

	
	
	
	

.end


