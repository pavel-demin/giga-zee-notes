/******************************************************************************
*
* 
* 
*
******************************************************************************/

/*****************************************************************************
*
* @file te_fsbl_hooks.c
* @author Antti Lukats
* @copyright 2015 Trenz Electronic GmbH
*
*
******************************************************************************/


#include "fsbl.h"
#include "xstatus.h"
//rename to correct board name
#include "te_fsbl_hooks_te0720.h"
#include "xparameters.h"

#include "xemacps.h"

#include "xdevcfg.h"
#include "xil_cache.h"

/************************** Constant Definitions *****************************/
#define TE0720

// uncomment to add default video init into FSBL
//#define TE_INIT_VIDEO
/* 
 * Settings to copy MAC address into OCM for u-boot usage in environment
 */
#define UBOOT_ENV_MAGIC 0xCAFEBABE
#define UBOOT_ENV_MAGIC_ADDR 0xFFFFFC00
#define UBOOT_ENV_ADDR 0xFFFFFC04

/************************** Variable Definitions *****************************/

/************************** Function Prototypes ******************************/

/*****************************************************************************/


#ifdef TE_INIT_VIDEO


#endif


#ifdef UBOOT_ENV_MAGIC

/******************************************************************************
* Convert a 4-bit value to hexadecimal representation (lowercase letters).
*
* @param x 4-bit value to be converted.
* @return Hexadecimal representation.
****************************************************************************/
static char Uint4ToHex(const unsigned char x)
{
	if (x<10) {
		return x + '0';
	} else {
		return x + ('a' - 10);
	}
}

/******************************************************************************
* Convert an octet to the hexadecimal representation (lowercase letters). A null byte is not appended.
*
* @param s Buffer to store hexadecimal representation. At least two bytes must be available.
* @param x Octet to be converted.
****************************************************************************/
static void Uint8ToHex(char* s, const unsigned char x)
{
	s[0] = Uint4ToHex((x >> 4) & 0x0F);
	s[1] = Uint4ToHex((x >> 0) & 0x0F);
}

/******************************************************************************
* Convert MAC address to the environment string for the U-Boot to read the MAC address from.
* Example: "ethaddr=00:0a:35:00:00:05\n"
*
* @param env Buffer to store the environment string. Must have at least 27 bytes available.
* @param mac_addr MAC address, 6 bytes.
****************************************************************************/
static void MacToUbootEnvironment(char* env, const unsigned char* mac_addr)
{
	// end of "ethaddr=".
	const int idx0 = 8;
	const int N_MAC = 6;
	int i;

	strcpy(env, "ethaddr=");
	for (i=0; i<N_MAC; ++i) {
		const int idx = idx0 + 3*i;
		Uint8ToHex(&env[idx], mac_addr[i]);
		env[idx+2] = ':';
	}
	env[idx0 + 3 * N_MAC - 1] = '\n';
	env[idx0 + 3 * N_MAC - 0] = 0;
}

#endif




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
u32 TE_FsblHookBeforeBitstreamDload_Custom(void)
{
	u32 Status;

	Status = XST_SUCCESS;
  
  xil_printf("\r\n--------------------------------------------------------------------------------\r\n");
  xil_printf("TE0720 TE_FsblHookBeforeBitstreamDload_Custom\r\n"); 
	/* Add the code here */
  xil_printf("\r\n--------------------------------------------------------------------------------\r\n");


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
u32 TE_FsblHookAfterBitstreamDload_Custom(void)
{
	u32 Status;

	Status = XST_SUCCESS;

  xil_printf("\r\n--------------------------------------------------------------------------------\r\n");
  xil_printf("TE0720 TE_FsblHookAfterBitstreamDload_Custom\r\n"); 
	/* Add the code here */
  xil_printf("\r\n--------------------------------------------------------------------------------\r\n");

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
u32 TE_FsblHookBeforeHandoff_Custom(void)
{
	u32 Status;

	Status = XST_SUCCESS;

  xil_printf("\r\n--------------------------------------------------------------------------------\r\n");
  xil_printf("TE0720 TE_FsblHookBeforeHandoff_Custom\r\n"); 
	/* Add the code here */
  
  u32 device;

	u16 rval16;
	u8 speed_grade;
	u8 pcb_rev;
	unsigned char temp_grade;
	unsigned char model1;
	unsigned char model2;
	unsigned char model3;

	XEmacPs Emac;
	XEmacPs_Config *Mac_Config;

	unsigned char mac_addr[6];
	int i = 0;


  #ifdef TE_VIDEO_INIT

  //	Status = adv7511_init(XPAR_XIICPS_0_DEVICE_ID, 0x00, ADV7511_ADDR);

    Status = tpg_init(XPAR_V_TPG_0_DEVICE_ID);	
    Status = vtc_init(XPAR_VTC_0_DEVICE_ID);
    Status = vdma_init(XPAR_AXI_VDMA_0_DEVICE_ID);

  #endif


  #ifdef TE0720


    Mac_Config = XEmacPs_LookupConfig(XPAR_PS7_ETHERNET_0_DEVICE_ID); if(Mac_Config == NULL) { return XST_FAILURE; }

    Status = XEmacPs_CfgInitialize(&Emac, Mac_Config, Mac_Config->BaseAddress); if(Status != XST_SUCCESS){ return XST_FAILURE; }
      /*
       * Read out MAC Address bytes
     */
    Status = XEmacPs_PhyRead(&Emac, 0x1A,  9, &rval16); if(Status != XST_SUCCESS){ return XST_FAILURE; }
    mac_addr[0] = (unsigned char)(rval16 >> 8);	
          mac_addr[1] = (unsigned char)(rval16 & 0xFF);
    Status = XEmacPs_PhyRead(&Emac, 0x1A,  10, &rval16); if(Status != XST_SUCCESS){	return XST_FAILURE; }
    mac_addr[2] = (unsigned char)(rval16 >> 8);	
          mac_addr[3] = (unsigned char)(rval16 & 0xFF);
    Status = XEmacPs_PhyRead(&Emac, 0x1A,  11, &rval16); if(Status != XST_SUCCESS){	return XST_FAILURE; }
    mac_addr[4] = (unsigned char)(rval16 >> 8);	
          mac_addr[5] = (unsigned char)(rval16 & 0xFF);

      /*
       * Decode SoM model and version information!
     */
    // Read register 3
    Status = XEmacPs_PhyRead(&Emac, 0x1A,  3, &rval16); if(Status != XST_SUCCESS){	return XST_FAILURE; }
    pcb_rev = (rval16 >>10) & 0x7;

    // Read register 4
    Status = XEmacPs_PhyRead(&Emac, 0x1A,  4, &rval16); if(Status != XST_SUCCESS){	return XST_FAILURE; }


    speed_grade = (rval16 >> 14) & 3;
    /* 0=C, 1=E, 2=I, 3=A */
    if ((rval16 & 0x3000)==0x0000) { temp_grade = 0x43; }
    else if ((rval16 & 0x3000)==0x1000) { temp_grade = 0x45; }
    else if ((rval16 & 0x3000)==0x2000) { temp_grade = 0x49; }
    else if ((rval16 & 0x3000)==0x3000) { temp_grade = 0x41; }
    else { temp_grade = 0x20; }
    
    if ((rval16 & 0x0F00)==0x000) { model1 = 0x20;model2 = 0x20;model3 = 0x46; } 
    else if ((rval16 & 0x0F00)==0x100) { model1 = 0x20;model2 = 0x20;model3 = 0x52; }
    else if ((rval16 & 0x0F00)==0x200) { model1 = 0x20;model2 = 0x4C;model3 = 0x46; }
    else if ((rval16 & 0x0F00)==0x300) { model1 = 0x31;model2 = 0x34;model3 = 0x53; }
    else { model1 = 0x31;model2 = 0x31;model3 = 0x31; }
    
    
    xil_printf("\n\rSoM: TE0720-0%d-%d%c%c%c%c SC REV:%02x", pcb_rev, speed_grade, temp_grade, model1, model2, model3, rval16 & 0xFF);
    xil_printf("\n\rMAC: ");

    for(i = 0; i < 6; i++) {
      xil_printf("%02x ", mac_addr[i]);
    }
    xil_printf("\n\r");
  #endif

    /*
     * Write MAC Address to OCM memory for u-boot to import!
     *
     */

    //strcpy(0xFFFFFC04, "ethaddr=00:0a:35:00:00:05\n" );
  #ifdef UBOOT_ENV_MAGIC
    Xil_Out32(UBOOT_ENV_MAGIC_ADDR, UBOOT_ENV_MAGIC); // Magic!
    MacToUbootEnvironment((char*)UBOOT_ENV_ADDR, mac_addr);
  #endif


      /*
       * Set MAC Address in PS7 IP Core registers
     */
    Status = XEmacPs_SetMacAddress(&Emac, mac_addr, 1); if(Status != XST_SUCCESS){ return XST_FAILURE; }



      /*
       * Marvell PHY Config
     */

          /* Select Page 18 */
    Status = XEmacPs_PhyWrite(&Emac, 0x00,  0x16, 0x0012); if(Status != XST_SUCCESS){ return XST_FAILURE; }
          /* Disable fiber/SGMII Autodetect */
    Status = XEmacPs_PhyWrite(&Emac, 0x00,  0x14, 0x8210); if(Status != XST_SUCCESS){ return XST_FAILURE; }

          /* Select Page 3 */
    Status = XEmacPs_PhyWrite(&Emac, 0x00,  0x16, 0x0003); if(Status != XST_SUCCESS){ return XST_FAILURE; }
          /* LED0: On link, Blink activity, LED1 Receive, LED2 Transmit */
    Status = XEmacPs_PhyWrite(&Emac, 0x00,  16, 0x0501); if(Status != XST_SUCCESS){ return XST_FAILURE; }
          /* LED polarity positive, push-pull on=high */
    Status = XEmacPs_PhyWrite(&Emac, 0x00,  17, 0x4415); if(Status != XST_SUCCESS){ return XST_FAILURE; }


          /* Select Page 0 */
    Status = XEmacPs_PhyWrite(&Emac, 0x00,  0x16, 0x0000); if(Status != XST_SUCCESS){ return XST_FAILURE; }
    
  #ifdef TE0720
      /*
       * SC LED remap
       * Green = ETH LED 0, Red = MIO7, NOSEQ output = ETH LED0
     */
    Status = XEmacPs_PhyWrite(&Emac, 0x1A,  5, 0x0041); if(Status != XST_SUCCESS){ return XST_FAILURE; }

      /*
       * Reset pulse to USB PHY
     */
    Status = XEmacPs_PhyWrite(&Emac, 0x1A,  7, 0x0010); if(Status != XST_SUCCESS){ return XST_FAILURE; }
    Status = XEmacPs_PhyWrite(&Emac, 0x1A,  7, 0x0000); if(Status != XST_SUCCESS){ return XST_FAILURE; }
  #endif
  
  
  xil_printf("\r\n--------------------------------------------------------------------------------\r\n");
  
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
void TE_FsblHookFallback_Custom(void)
{
  
  xil_printf("\r\n--------------------------------------------------------------------------------\r\n");
  xil_printf("TE0720 TE_FsblHookFallback_Custom\r\n"); 
	/* Add the code here */
  xil_printf("\r\n--------------------------------------------------------------------------------\r\n");
  
  
	//while(1);
}


