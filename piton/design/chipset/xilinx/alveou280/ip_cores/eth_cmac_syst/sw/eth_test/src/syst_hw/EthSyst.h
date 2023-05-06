/*****************************************************************************/
/**
*
* @file Initially started from Xilinx xemaclite.h
*
* Copyright (C) 2004 - 2020 Xilinx, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
*
* @addtogroup emaclite_v4_6
* @{
* @details
*
* The Xilinx Ethernet Lite (EmacLite) driver. This driver supports the Xilinx
* Ethernet Lite 10/100 MAC (EmacLite).
*
* The Xilinx Ethernet Lite 10/100 MAC supports the following features:
*   - Media Independent Interface (MII) for connection to external
*     10/100 Mbps PHY transceivers
*   - Independent internal transmit and receive buffers
*   - CSMA/CD compliant operations for half-duplex modes
*   - Unicast and broadcast
*   - Automatic FCS insertion
*   - Automatic pad insertion on transmit
*   - Configurable ping/pong buffers for either/both transmit and receive
*     buffer areas
*   - Interrupt driven mode
*   - Internal loop back
*   - MDIO Support to access PHY Registers
*
* The Xilinx Ethernet Lite 10/100 MAC does not support the following features:
*   - multi-frame buffering
*     only 1 transmit frame is allowed into each transmit buffer,
*     only 1 receive frame is allowed into each receive buffer.
*     the hardware blocks reception until buffer is emptied
*   - Pause frame (flow control) detection in full-duplex mode
*   - Programmable inter frame gap
*   - Multicast and promiscuous address filtering
*   - Automatic source address insertion or overwrite
*
* <b>Driver Description</b>
*
* The device driver enables higher layer software (e.g., an application) to
* communicate to the EmacLite. The driver handles transmission and reception
* of Ethernet frames, as well as configuration of the controller. It does not
* handle protocol stack functionality such as Link Layer Control (LLC) or the
* Address Resolution Protocol (ARP). The protocol stack that makes use of the
* driver handles this functionality. This implies that the driver is simply a
* pass-through mechanism between a protocol stack and the EmacLite.
*
* Since the driver is a simple pass-through mechanism between a protocol stack
* and the EmacLite, no assembly or disassembly of Ethernet frames is done at
* the driver-level. This assumes that the protocol stack passes a correctly
* formatted Ethernet frame to the driver for transmission, and that the driver
* does not validate the contents of an incoming frame. A single device driver
* can support multiple EmacLite devices.
*
* The driver supports interrupt driven mode and the default mode of operation
* is polled mode. If interrupts are desired, XEmacLite_InterruptEnable() must
* be called.
*
* <b>Device Configuration</b>
*
* The device can be configured in various ways during the FPGA implementation
* process.  Configuration parameters are stored in the xemaclite_g.c file.
* A table is defined where each entry contains configuration information for an
* EmacLite device. This information includes such things as the base address
* of the memory-mapped device and the number of buffers.
*
* <b>Interrupt Processing</b>
*
* After _Initialize is called, _InterruptEnable can be called to enable the
* interrupt driven functionality. If polled operation is desired, just call
* _Send and check the return code. If XST_FAILURE is returned, call _Send with
* the same data until XST_SUCCESS is returned. The same idea applies to _Recv.
* Call _Recv until the returned length is non-zero at which point the received
* data is in the buffer provided in the function call.
*
* The Transmit and Receive interrupts are enabled within the _InterruptEnable
* function and disabled in the _InterruptDisable function. The _Send and _Recv
* functions acknowledge the EmacLite generated interrupts associated with each
* function.
* It is the application's responsibility to acknowledge any associated Interrupt
* Controller interrupts if it is used in the system.
*
* <b>Memory Buffer Alignment</b>
*
* The alignment of the input/output buffers for the _Send and _Recv routine is
* not required to be 32 bits. If the buffer is not aligned on a 32-bit boundary
* there will be a performance impact while the driver aligns the data for
* transmission or upon reception.
*
* For optimum performance, the user should provide a 32-bit aligned buffer
* to the _Send and _Recv routines.
*
* <b>Asserts</b>
*
* Asserts are used within all Xilinx drivers to enforce constraints on argument
* values. Asserts can be turned off on a system-wide basis by defining, at
* compile time, the NDEBUG identifier.  By default, asserts are turned on and it
* is recommended that application developers leave asserts on during
* development.
*
* @note
*
* This driver requires EmacLite hardware version 1.01a and higher. It is not
* compatible with earlier versions of the EmacLite hardware. Use version 1.00a
* software driver for hardware version 1.00a/b.
*
* The RX hardware is enabled from powerup and there is no disable. It is
* possible that frames have been received prior to the initialization
* of the driver. If this situation is possible, call XEmacLite_FlushReceive()
* to empty the receive buffers after initialization.
*
* This driver is intended to be RTOS and processor independent.  It works
* with physical addresses only.  Any needs for dynamic memory management,
* threads or thread mutual exclusion, virtual memory, or cache control must
* be satisfied by the layer above this driver.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.01a ecm  01/30/04 First release
* 1.11a mta  03/21/07 Updated to new coding style
* 1.12a mta  11/28/07 Added the function XEmacLite_CfgInitialize,
*		      moved the functions XEmacLite_LookupConfig and
*		      XEmacLite_Initialize to xemaclite_sinit.c for removing
*		      the dependency on the static config table and
*		      xparameters.h from the driver initialization
* 1.13a sv   02/1/08  Updated the TxBufferAvailable routine to return
*		      busy status properly and added macros for Tx/Rx status
* 1.14a sdm  08/22/08 Removed support for static interrupt handlers from the MDD
*		      file
* 2.00a ktn  02/16/09 Added support for MDIO and internal loop back
* 2.01a ktn  07/20/09 Updated the XEmacLite_AlignedWrite and
*                     XEmacLite_AlignedRead functions to use volatile
*                     variables so that they are not optimized.
*                     Modified the XEmacLite_EnableInterrupts and
*                     XEmacLite_DisableInterrupts functions to enable/disable
*                     the interrupt in the Ping buffer as this is used to enable
*                     the interrupts for both Ping and Pong Buffers.
*                     The interrupt enable bit in the Pong buffer is not used by
*                     the HW.
*                     Modified XEmacLite_Send function to use Ping buffers
*                     Interrupt enable bit since this alone is used to enable
*                     the interrupts for both Ping and Pong Buffers.
* 3.00a ktn  10/22/09 Updated driver to use the HAL Processor APIs/macros.
*		      The macros have been renamed to remove _m from the name in
*		      all the driver files.
*		      The macros changed in this file are
*		      XEmacLite_mNextTransmitAddr is XEmacLite_NextTransmitAddr,
*		      XEmacLite_mNextReceiveAddr is XEmacLite_NextReceiveAddr,
*		      XEmacLite_mIsMdioConfigured is XEmacLite_IsMdioConfigured,
*		      XEmacLite_mIsLoopbackConfigured is
*		      XEmacLite_IsLoopbackConfigured.
*		      See xemaclite_i.h for the macros which have changed.
* 3.01a ktn  07/08/10 The macro XEmacLite_GetReceiveDataLength in the
*		      xemaclite.c file is changed to a static function.
*		      XEmacLite_GetReceiveDataLength and XEmacLite_Recv
*		      functions  are updated to support little endian
*		      MicroBlaze.
* 3.02a sdm  07/22/11 Removed redundant code in XEmacLite_Recv functions for
*		      CR617290
* 3.03a asa  04/05/12 Defined the flag __LITTLE_ENDIAN__ for cases where the
*		      driver is compiled with ARM toolchain.
* 3.04a srt  04/13/13 Removed warnings (CR 705000).
* 4.0   adk  19/12/13 Updated as per the New Tcl API's
* 4.1	nsk  07/13/15 Added Length check in XEmacLite_AlignedWrite function
*		      in xemaclite_l.c file to avoid extra write operation
*		      (CR 843707).
* 4.2   sk   11/10/15 Used UINTPTR instead of u32 for Baseaddress CR# 867425.
*                     Changed the prototype of XEmacLite_CfgInitialize API.
* 4.2   adk  11/18/15 Fix compilation errors due to conflicting data types
*		      CR#917930
* 4.2	adk  29/02/16 Updated interrupt example to support Zynq and ZynqMP
*		      CR#938244.
* 4.3   asa  08/27/16 Fix compilation warning by making change xemaclite_l.c
*       ms   01/23/17 Added xil_printf statement in main function for all
*                     examples to ensure that "Successfully ran" and "Failed"
*                     strings are available in all examples. This is a fix
*                     for CR-965028.
*       ms   03/17/17 Modified text file in examples folder for doxygen
*                     generation.
*
* </pre>
*
*
******************************************************************************/
#ifndef ETHDRV_H  // prevent circular inclusions
#define ETHDRV_H  // by using protection macros

/***************************** Include Files *********************************/
#include "xparameters.h"
#include "xtmrctr.h"
#include "xaxidma.h"
#include "Eth_CMAC_syst_eth100gb_0_axi4_lite_registers.h" // generated during implementation if AXI-Lite is enabled in Ethernet core
#include "xgpio.h"
#include "xaxis_switch.h"


/**************************** Type Definitions *******************************/
class EthSyst {
  uint32_t volatile* ethSystBase; // Whole Ethernet system base address
  uint32_t volatile* ethCore;     // Ethernet core base address
  //100Gb Ethernet subsystem registers: https://www.xilinx.com/support/documentation/ip_documentation/cmac_usplus/v3_1/pg203-cmac-usplus.pdf#page=177
  enum {
    GT_RESET_REG          = GT_RESET_REG_OFFSET          / sizeof(uint32_t),
    RESET_REG             = RESET_REG_OFFSET             / sizeof(uint32_t),
    CORE_VERSION_REG      = CORE_VERSION_REG_OFFSET      / sizeof(uint32_t),
    CORE_MODE_REG         = CORE_MODE_REG_OFFSET         / sizeof(uint32_t),
    SWITCH_CORE_MODE_REG  = SWITCH_CORE_MODE_REG_OFFSET  / sizeof(uint32_t),
    CONFIGURATION_TX_REG1 = CONFIGURATION_TX_REG1_OFFSET / sizeof(uint32_t),
    CONFIGURATION_RX_REG1 = CONFIGURATION_RX_REG1_OFFSET / sizeof(uint32_t),
    STAT_TX_STATUS_REG    = STAT_TX_STATUS_REG_OFFSET    / sizeof(uint32_t),
    STAT_RX_STATUS_REG    = STAT_RX_STATUS_REG_OFFSET    / sizeof(uint32_t),
    GT_LOOPBACK_REG       = GT_LOOPBACK_REG_OFFSET       / sizeof(uint32_t)
  };
  // Ethernet core control via pins
  uint32_t volatile* rxtxCtrl;
  enum {
    TX_CTRL = XGPIO_DATA_OFFSET  / sizeof(uint32_t),
    RX_CTRL = XGPIO_DATA2_OFFSET / sizeof(uint32_t)
  };

  void     dmaBDSetup(bool);
  uint32_t dmaBDCheck(bool);
  void alignedWrite(void*, unsigned);
  void alignedRead (void*, unsigned);
  uint16_t getReceiveDataLength(uint16_t);
  
  public:
  XTmrCtr timerCnt; // Instance of Timer counter
  XAxiDma axiDma;   // AXI DMA instance definitions
  // DMA Scatter-Gather memory Rx/Tx distribution
  float const TIMER_TICK = 10.; //ns
  enum {
    ETH_MIN_PACK_SIZE = 64, // Limitations in 100Gb Ethernet IP (set in Vivado)
    ETH_MAX_PACK_SIZE = 9600,
    // DMA physical addresses, DMA doesn't see CPU address space, just own memories, so full address is not needed
    TX_DMA_MEM_ADDR = 0, // ETH_SYST_BASEADDR + TX_MEM_CPU_BASEADDR,
    RX_DMA_MEM_ADDR = 0, // ETH_SYST_BASEADDR + RX_MEM_CPU_BASEADDR,
    TX_SG_MEM_SIZE  = SG_MEM_CPU_ADRRANGE/2,
    RX_SG_MEM_SIZE  = SG_MEM_CPU_ADRRANGE/2,
    TX_SG_MEM_ADDR  = 0,              //   ETH_SYST_BASEADDR + SG_MEM_CPU_BASEADDR,
    RX_SG_MEM_ADDR  = TX_SG_MEM_SIZE, // + ETH_SYST_BASEADDR + SG_MEM_CPU_BASEADDR,
  };
  uint32_t volatile* txMem;   // Tx mem base address
  uint32_t volatile* rxMem;   // Rx mem base address
  uint32_t volatile* sgMem;   // SG mem base address
  uint32_t volatile* sgTxMem; // Tx SG mem base address
  uint32_t volatile* sgRxMem; // Rx SG mem base address

  size_t txBdCount = 0;
  size_t rxBdCount = 0;

  // Indicator of physical connection wait order (reaching zero while waiting for connection indicates Eth instance as first connected)
  uint8_t physConnOrder;
  enum {PHYS_CONN_WAIT_INI = 2};

  EthSyst();
  // ~EthSyst();
  void ethCoreInit(bool);
  void ethTxRxEnable();
  void ethTxRxDisable();

  void axiDmaInit();
  XAxiDma_Bd* dmaBDAlloc   (bool, size_t, size_t, size_t, size_t);
  void        dmaBDTransfer(bool, size_t, size_t, XAxiDma_Bd*);
  XAxiDma_Bd* dmaBDPoll    (bool, size_t);
  void        dmaBDFree    (bool, size_t, size_t, XAxiDma_Bd*);
  void switch_LB_DMA_Eth   (bool, bool);

  void timerCntInit();

  void ethSystInit();

  int flushReceive();
  int frameSend(uint8_t*, unsigned);
  uint16_t frameRecv(uint8_t*);
};

#endif // end of protection macro
