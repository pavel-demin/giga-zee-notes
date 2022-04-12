/******************************************************************************
*
* 
*
******************************************************************************/

/*****************************************************************************
*
* @file te_fsbl_hooks.c
*
*
******************************************************************************/


#include "fsbl.h"
#include "xstatus.h"
#include "te_fsbl_hooks.h"
#include "xparameters.h"

/************************** Variable Definitions *****************************/
/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are only defined here such that a user can easily
 * change all the needed parameters in one place.
 */
#define DCFG_DEVICE_ID		XPAR_XDCFG_0_DEVICE_ID

/**
 * @name Configuration Type1 packet headers masks
 * @{
 */
#define XDC_TYPE_SHIFT			29
#define XDC_REGISTER_SHIFT		13
#define XDC_OP_SHIFT			27
#define XDC_TYPE_1			1
#define OPCODE_READ			1
/* @} */

/*
 * Addresses of the Configuration Registers
 */
#define CRC		0	/* Status Register */
#define FAR		1	/* Frame Address Register */
#define FDRI		2	/* FDRI Register */
#define FDRO		3	/* FDRO Register */
#define CMD		4	/* Command Register */
#define CTL0		5	/* Control Register 0 */
#define MASK		6	/* MASK Register */
#define STAT		7	/* Status Register */
#define LOUT		8	/* LOUT Register */
#define COR0		9	/* Configuration Options Register 0 */
#define MFWR		10	/* MFWR Register */
#define CBC		11	/* CBC Register */
#define IDCODE		12	/* IDCODE Register */
#define AXSS		13	/* AXSS Register */
#define COR1		14	/* Configuration Options Register 1 */
#define WBSTAR		15	/* Warm Boot Start Address Register */
#define TIMER		16	/* Watchdog Timer Register */
#define BOOTSTS		17	/* Boot History Status Register */
#define CTL1		18	/* Control Register 1 */

/************************** Function Prototypes ******************************/

XDcfg DcfgInstance;		/* Device Configuration Interface Instance */
/*****************************************************************************/

/*
 * read IDCODE over PCAP
 *
 */

u32 XDcfg_RegAddr(u8 Register, u8 OpCode, u8 Size)
{
	/*
	 * Type 1 Packet Header Format
	 * The header section is always a 32-bit word.
	 *
	 * HeaderType | Opcode | Register Address | Reserved | Word Count
	 * [31:29]	[28:27]		[26:13]	     [12:11]     [10:0]
	 * --------------------------------------------------------------
	 *   001 	  xx 	  RRRRRRRRRxxxxx	RR	xxxxxxxxxxx
	 *
	 * �R� means the bit is not used and reserved for future use.
	 * The reserved bits should be written as 0s.
	 *
	 * Generating the Type 1 packet header which involves sifting of Type 1
	 * Header Mask, Register value and the OpCode which is 01 in this case
	 * as only read operation is to be carried out and then performing OR
	 * operation with the Word Length.
	 */
	return ( ((XDC_TYPE_1 << XDC_TYPE_SHIFT) |
		(Register << XDC_REGISTER_SHIFT) |
		(OpCode << XDC_OP_SHIFT)) | Size);
}


int XDcfg_GetConfigReg(XDcfg *DcfgInstancePtr, u32 ConfigReg, u32 *RegData)
{
	u32 IntrStsReg;
	u32 StatusReg;
	unsigned int CmdIndex;
	unsigned int CmdBuf[18];

	/*
	 * Clear the interrupt status bits
	 */
	XDcfg_IntrClear(DcfgInstancePtr, (XDCFG_IXR_PCFG_DONE_MASK |
			XDCFG_IXR_D_P_DONE_MASK | XDCFG_IXR_DMA_DONE_MASK));

	/* Check if DMA command queue is full */
	StatusReg = XDcfg_ReadReg(DcfgInstancePtr->Config.BaseAddr,
				XDCFG_STATUS_OFFSET);
	if ((StatusReg & XDCFG_STATUS_DMA_CMD_Q_F_MASK) ==
			XDCFG_STATUS_DMA_CMD_Q_F_MASK) {
		return XST_FAILURE;
	}

	/*
	 * Register Readback in non secure mode
	 * Create the data to be written to read back the
	 * Configuration Registers from PL Region.
	 */
	CmdIndex = 0;
	CmdBuf[CmdIndex++] = 0xFFFFFFFF; 	/* Dummy Word */
	CmdBuf[CmdIndex++] = 0xFFFFFFFF; 	/* Dummy Word */
	CmdBuf[CmdIndex++] = 0xFFFFFFFF; 	/* Dummy Word */
	CmdBuf[CmdIndex++] = 0xFFFFFFFF; 	/* Dummy Word */
	CmdBuf[CmdIndex++] = 0xFFFFFFFF; 	/* Dummy Word */
	CmdBuf[CmdIndex++] = 0xFFFFFFFF; 	/* Dummy Word */
	CmdBuf[CmdIndex++] = 0xFFFFFFFF; 	/* Dummy Word */
	CmdBuf[CmdIndex++] = 0xFFFFFFFF; 	/* Dummy Word */
	CmdBuf[CmdIndex++] = 0x000000BB; 	/* Bus Width Sync Word */
	CmdBuf[CmdIndex++] = 0x11220044; 	/* Bus Width Detect */
	CmdBuf[CmdIndex++] = 0xFFFFFFFF; 	/* Dummy Word */
	CmdBuf[CmdIndex++] = 0xAA995566; 	/* Sync Word */
	CmdBuf[CmdIndex++] = 0x20000000; 	/* Type 1 NOOP Word 0 */
	CmdBuf[CmdIndex++] = XDcfg_RegAddr(ConfigReg,OPCODE_READ,0x1);
	CmdBuf[CmdIndex++] = 0x20000000; 	/* Type 1 NOOP Word 0 */
	CmdBuf[CmdIndex++] = 0x20000000; 	/* Type 1 NOOP Word 0 */

	XDcfg_Transfer(&DcfgInstance, (&CmdBuf[0]),
			CmdIndex, RegData, 1, XDCFG_PCAP_READBACK);

	/* Poll IXR_DMA_DONE */
	IntrStsReg = XDcfg_IntrGetStatus(DcfgInstancePtr);
	while ((IntrStsReg & XDCFG_IXR_DMA_DONE_MASK) !=
			XDCFG_IXR_DMA_DONE_MASK) {
		IntrStsReg = XDcfg_IntrGetStatus(DcfgInstancePtr);
	}

	/* Poll IXR_D_P_DONE */
	while ((IntrStsReg & XDCFG_IXR_D_P_DONE_MASK) !=
			XDCFG_IXR_D_P_DONE_MASK) {
		IntrStsReg = XDcfg_IntrGetStatus(DcfgInstancePtr);
	}

	CmdIndex = 0;
	CmdBuf[CmdIndex++] = 0x30008001;	/* Dummy Word */
	CmdBuf[CmdIndex++] = 0x0000000D;	/* Bus Width Sync Word */
	CmdBuf[CmdIndex++] = 0x20000000;	/* Bus Width Detect */
	CmdBuf[CmdIndex++] = 0x20000000;	/* Dummy Word */
	CmdBuf[CmdIndex++] = 0x20000000;	/* Bus Width Detect */
	CmdBuf[CmdIndex++] = 0x20000000;	/* Dummy Word */

	XDcfg_InitiateDma(DcfgInstancePtr, (u32)(&CmdBuf[0]),
				XDCFG_DMA_INVALID_ADDRESS, CmdIndex, 0);

	/* Poll IXR_DMA_DONE */
	IntrStsReg = XDcfg_IntrGetStatus(DcfgInstancePtr);
	while ((IntrStsReg & XDCFG_IXR_DMA_DONE_MASK) !=
			XDCFG_IXR_DMA_DONE_MASK) {
		IntrStsReg = XDcfg_IntrGetStatus(DcfgInstancePtr);
	}

	/* Poll IXR_D_P_DONE */
	while ((IntrStsReg & XDCFG_IXR_D_P_DONE_MASK) !=
			XDCFG_IXR_D_P_DONE_MASK) {
		IntrStsReg = XDcfg_IntrGetStatus(DcfgInstancePtr);
	}

	return XST_SUCCESS;
}

u32 te_read_IDCODE(void)
{
  int Status;
  unsigned int ValueBack;
  unsigned int tmval;
  XDcfg_Config *ConfigPtr;

  /*
   * Initialize the Device Configuration Interface driver.
   */
  ConfigPtr = XDcfg_LookupConfig(DCFG_DEVICE_ID);

  /*
   * This is where the virtual address would be used, this example
   * uses physical address.
   */
  Status = XDcfg_CfgInitialize(&DcfgInstance, ConfigPtr,
          ConfigPtr->BaseAddr);
  if (Status != XST_SUCCESS) {
    return XST_FAILURE;
  }

  /*
   * Run the Self test.
   */
  Status = XDcfg_SelfTest(&DcfgInstance);
  if (Status != XST_SUCCESS) {
    return XST_FAILURE;
  }


  if (XDcfg_GetConfigReg(&DcfgInstance, IDCODE, (u32 *)&ValueBack) !=
    XST_SUCCESS) {
    return XST_FAILURE;
  }
  
  xil_printf("\r\nDevice IDCODE: %x", ValueBack );
  tmval=(ValueBack & 0x0001F000)>>12;
  xil_printf("\r\nDevice Name: ");
  if (tmval>>12==0x08) { xil_printf("7z014s");}
  else if (tmval==0x02) { xil_printf("7z010");}
  else if (tmval==0x1b) { xil_printf("7z015");}
  else if (tmval==0x07) { xil_printf("7z020");}
  else if (tmval==0x0c) { xil_printf("7z030");}
  else if (tmval==0x11) { xil_printf("7z045");}
  else {  xil_printf("(...)", tmval);}
  xil_printf(" (%x)", tmval);
  tmval=(ValueBack & 0xF0000000)>>28;
  xil_printf("\r\nDevice Revision: %x ", tmval);
  return XST_SUCCESS;
}
/******************************************************************************
* This function is the hook which will be called  before the bitstream download.
* The user can add all the customized code required to be executed before the
* bitstream download to this routine.
*
* @param None
*
* @return
*		- XST_SUCCESS to indicate success
*		- XST_FAILURE.to indicate failure
*
****************************************************************************/
u32 TE_FsblHookBeforeBitstreamDload(void)
{
	u32 Status;

	Status = XST_SUCCESS;

	/*
	 * User logic to be added here. Errors to be stored in the status variable
	 * and returned
	 */
	fsbl_printf(DEBUG_INFO,"In FsblHookBeforeBitstreamDload function \r\n");
  
  #if defined(ENABLE_TE_HOOKS_BD)
    Status = TE_FsblHookBeforeBitstreamDload_Custom();
  #endif  

	return (Status);
}

/******************************************************************************
* This function is the hook which will be called  after the bitstream download.
* The user can add all the customized code required to be executed after the
* bitstream download to this routine.
*
* @param None
*
* @return
*		- XST_SUCCESS to indicate success
*		- XST_FAILURE.to indicate failure
*
****************************************************************************/
u32 TE_FsblHookAfterBitstreamDload(void)
{
	u32 Status;

	Status = XST_SUCCESS;

	/*
	 * User logic to be added here.
	 * Errors to be stored in the status variable and returned
	 */
	fsbl_printf(DEBUG_INFO, "In FsblHookAfterBitstreamDload function \r\n");
  #if defined(ENABLE_TE_HOOKS_AD)
    Status = TE_FsblHookAfterBitstreamDload_Custom();
  #endif  

	return (Status);
}

/******************************************************************************
* This function is the hook which will be called  before the FSBL does a handoff
* to the application. The user can add all the customized code required to be
* executed before the handoff to this routine.
*
* @param None
*
* @return
*		- XST_SUCCESS to indicate success
*		- XST_FAILURE.to indicate failure
*
****************************************************************************/
u32 TE_FsblHookBeforeHandoff(void)
{
	u32 Status;

	Status = XST_SUCCESS;

	/*
	 * User logic to be added here.
	 * Errors to be stored in the status variable and returned
	 */
	fsbl_printf(DEBUG_INFO,"In FsblHookBeforeHandoff function \r\n");

  Status = te_read_IDCODE(); // general include to display Device ID of the zynq
  #if defined(ENABLE_TE_HOOKS_BH)
    Status = TE_FsblHookBeforeHandoff_Custom();
  #endif  
  
	return (Status);
}


/******************************************************************************
* This function is the hook which will be called in case FSBL fall back
*
* @param None
*
* @return None
*
****************************************************************************/
void TE_FsblHookFallback(void)
{
	/*
	 * User logic to be added here.
	 * Errors to be stored in the status variable and returned
	 */
	fsbl_printf(DEBUG_INFO,"In FsblHookFallback function \r\n");
  
  #if defined(ENABLE_TE_HOOKS_FB)
    TE_FsblHookFallback_Custom();
  #endif  
  
	while(1);
}


