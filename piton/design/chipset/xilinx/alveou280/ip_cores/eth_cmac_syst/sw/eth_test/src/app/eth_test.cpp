
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <algorithm>
// #include <vector>
// #include <string>
// #include <xil_sleeptimer.h>
// #include <cassert>
// #include <iostream>
// #include <fstream>
// #include <sstream>
// #include <thread>
// #include <chrono>
// #include <fcntl.h>
// #include <sys/stat.h>

#include "EthSyst.h"
#include "ping_test.h"

// using namespace std;

int udp_perf_client();
int udp_perf_server();
int tcp_perf_client();
int tcp_perf_server();

bool txIntrProcessed;
void dmaTxTestHandler() {
  printf("Tx Handler has started: %d\n", txIntrProcessed);
  // Indicate the interrupt has been processed using a shared variable.
	txIntrProcessed = true;
}
void dmaTxTestFastHandler() {
  printf("Fast ");
  dmaTxTestHandler();
}

bool rxIntrProcessed;
void dmaRxTestHandler()
{
  printf("Rx Handler has started: %d\n", rxIntrProcessed);
  // Indicate the interrupt has been processed using a shared variable.
	rxIntrProcessed = true;
}
void dmaRxTestFastHandler() {
  printf("Fast ");
  dmaRxTestHandler();
}

int main(int argc, char *argv[])
{
  EthSyst ethSyst; // Instance of the Ethernet System driver
  // Tx/Rx memories 
  size_t const txMemSize  = TX_MEM_CPU_ADRRANGE;
  size_t const rxMemSize  = RX_MEM_CPU_ADRRANGE;
  size_t const sgMemSize  = SG_MEM_CPU_ADRRANGE;
  size_t const txrxMemSize = std::min(txMemSize, rxMemSize);
  size_t const txMemWords = txMemSize / sizeof(uint32_t);
  size_t const rxMemWords = rxMemSize / sizeof(uint32_t);
  size_t const sgMemWords = sgMemSize / sizeof(uint32_t);

  enum {ETH_WORD_SIZE = ETH_DMA_AXIS_WIDTH / 8,
        DMA_AXI_BURST = ETH_WORD_SIZE * std::max(XPAR_AXI_DMA_0_MM2S_BURST_SIZE, // the parameter set in Vivado AXI_DMA IP
                                                 XPAR_AXI_DMA_0_S2MM_BURST_SIZE),
        DMA_PACKET_LEN   = txrxMemSize/3     - sizeof(uint32_t), // the parameter to play with (no issies met for any values and granularities)
        ETH_PACKET_LEN   = ETH_WORD_SIZE*150 - sizeof(uint32_t), // the parameter to play with (no issues met for granularity=sizeof(uint32_t) and range=[(1...~150)*ETH_WORD_SIZE]
                                                                 // (defaults in Eth100Gb IP as min/max packet length=64...9600(but only upto 9596 works)))
        ETH_MEMPACK_SIZE = ETH_PACKET_LEN > DMA_AXI_BURST/2  ? ((ETH_PACKET_LEN + DMA_AXI_BURST-1) / DMA_AXI_BURST) * DMA_AXI_BURST :
                           ETH_PACKET_LEN > DMA_AXI_BURST/4  ? DMA_AXI_BURST/2  :
                           ETH_PACKET_LEN > DMA_AXI_BURST/8  ? DMA_AXI_BURST/4  :
                           ETH_PACKET_LEN > DMA_AXI_BURST/16 ? DMA_AXI_BURST/8  :
                           ETH_PACKET_LEN > DMA_AXI_BURST/32 ? DMA_AXI_BURST/16 : ETH_PACKET_LEN
        // ETH_PACKET_DECR = 7*sizeof(uint32_t) // optional length decrement for some packets for test purposes
  };


  while (true) {

    printf("\n");
    printf("------ Ethernet Test App ------\n");
    printf("Please enter test mode:\n");
    printf("  Single board self-diag/loopback tests: l\n");
    printf("  Two boards diag communication tests:   c\n");
    printf("  Two boards IP-based tests:             i\n");
    printf("  Finish:                                f\n");
    char choice;
    scanf("%s", &choice);
    printf("You have entered: %c\n\n", choice);


    switch (choice) {
      case 'l': {
        printf("------- Running DMA Tx/Rx/SG memory test -------\n");
        printf("Checking memories with random values from %0X to %0X \n", 0, RAND_MAX);
        // first clearing previously stored values
        for (size_t addr = 0; addr < txMemWords; ++addr) ethSyst.txMem[addr] = 0;
        for (size_t addr = 0; addr < rxMemWords; ++addr) ethSyst.rxMem[addr] = 0;
        for (size_t addr = 0; addr < sgMemWords; ++addr) ethSyst.sgMem[addr] = 0;

        uint8_t  volatile* txMem8  = reinterpret_cast<uint8_t  volatile*>(ethSyst.txMem);
        uint16_t volatile* txMem16 = reinterpret_cast<uint16_t volatile*>(ethSyst.txMem);
        uint32_t volatile* txMem32 = reinterpret_cast<uint32_t volatile*>(ethSyst.txMem);
        uint64_t volatile* txMem64 = reinterpret_cast<uint64_t volatile*>(ethSyst.txMem);
        uint8_t  volatile* rxMem8  = reinterpret_cast<uint8_t  volatile*>(ethSyst.rxMem);
        uint16_t volatile* rxMem16 = reinterpret_cast<uint16_t volatile*>(ethSyst.rxMem);
        uint32_t volatile* rxMem32 = reinterpret_cast<uint32_t volatile*>(ethSyst.rxMem);
        uint64_t volatile* rxMem64 = reinterpret_cast<uint64_t volatile*>(ethSyst.rxMem);
        uint8_t  volatile* sgMem8  = reinterpret_cast<uint8_t  volatile*>(ethSyst.sgMem);
        uint16_t volatile* sgMem16 = reinterpret_cast<uint16_t volatile*>(ethSyst.sgMem);
        uint32_t volatile* sgMem32 = reinterpret_cast<uint32_t volatile*>(ethSyst.sgMem);
        uint64_t volatile* sgMem64 = reinterpret_cast<uint64_t volatile*>(ethSyst.sgMem);
        size_t const axiWidth = 512 / 8;

        // filling the memories with random values
        srand(1);
        uint64_t val = 0;
        for (size_t addr = 0; addr < txMemSize; ++addr) {
          uint64_t rand64 = rand();
          val = (val >> 8) | (rand64 << 56);
          size_t axiWordIdx = addr/axiWidth;
          // changing written data type every wide AXI word
          if (axiWordIdx%4 == 0) txMem8 [addr  ] = val >> 56;
          if (axiWordIdx%4 == 1) txMem16[addr/2] = val >> 48;
          if (axiWordIdx%4 == 2) txMem32[addr/4] = val >> 32;
          if (axiWordIdx%4 == 3) txMem64[addr/8] = val;
        }
        for (size_t addr = 0; addr < rxMemSize; ++addr) {
          uint64_t rand64 = rand();
          val = (val >> 8) | (rand64 << 56);
          size_t axiWordIdx = addr/axiWidth;
          // changing written data type every wide AXI word
          if (axiWordIdx%4 == 0) rxMem8 [addr  ] = val >> 56;
          if (axiWordIdx%4 == 1) rxMem16[addr/2] = val >> 48;
          if (axiWordIdx%4 == 2) rxMem32[addr/4] = val >> 32;
          if (axiWordIdx%4 == 3) rxMem64[addr/8] = val;
        }
        for (size_t addr = 0; addr < sgMemSize; ++addr) {
          uint64_t rand64 = rand();
          val = (val >> 8) | (rand64 << 56);
          size_t axiWordIdx = addr/axiWidth;
          // changing written data type every wide AXI word
          if (axiWordIdx%4 == 0) sgMem8 [addr  ] = val >> 56;
          if (axiWordIdx%4 == 1) sgMem16[addr/2] = val >> 48;
          if (axiWordIdx%4 == 2) sgMem32[addr/4] = val >> 32;
          if (axiWordIdx%4 == 3) sgMem64[addr/8] = val;
        }

        // checking written values
        srand(1);
        val = 0;
        printf("Checking TX memory at addr 0x%lX(virt: 0x%lX) with size %ld \n", ETH_SYST_BASEADDR+TX_MEM_CPU_BASEADDR, size_t(ethSyst.txMem), txMemSize);
        for (size_t addr = 0; addr < txMemSize; ++addr) {
          uint64_t rand64 = rand();
          val = (val >> 8) | (rand64 << 56);
          // checking readback using different data types
          if (                 txMem8 [addr  ] != (val >> 56)) {
            printf("\nERROR: Incorrect readback of Byte at addr %lx from Tx Mem: %x, expected: %lx \n", addr, txMem8[addr], val >> 56);
            exit(1);
          }
          if ((addr%2) == 1 && txMem16[addr/2] != (val >> 48)) {
            printf("\nERROR: Incorrect readback of Word-16 at addr %lx from Tx Mem: %x, expected: %lx \n", addr, txMem16[addr/2], val >> 48);
            exit(1);
          }
          if ((addr%4) == 3 && txMem32[addr/4] != (val >> 32)) {
            printf("\nERROR: Incorrect readback of Word-32 at addr %lx from Tx Mem: %x, expected: %lx \n", addr, txMem32[addr/4], val >> 32);
            exit(1);
          }
          if ((addr%8) == 7 && txMem64[addr/8] !=  val)        {
            printf("\nERROR: Incorrect readback of Word-64 at addr %lx from Tx Mem: %lx, expected: %lx \n", addr, txMem64[addr/8], val);
            exit(1);
          }
        }
        printf("Checking RX memory at addr 0x%lX(virt: 0x%lX) with size %ld \n", ETH_SYST_BASEADDR+RX_MEM_CPU_BASEADDR, size_t(ethSyst.rxMem), rxMemSize);
        for (size_t addr = 0; addr < rxMemSize; ++addr) {
          uint64_t rand64 = rand();
          val = (val >> 8) | (rand64 << 56);
          // checking readback using different data types
          if (                 rxMem8 [addr  ] != (val >> 56)) {
            printf("\nERROR: Incorrect readback of Byte at addr %lx from Rx Mem: %x, expected: %lx \n", addr, rxMem8[addr], val >> 56);
            exit(1);
          }
          if ((addr%2) == 1 && rxMem16[addr/2] != (val >> 48)) {
            printf("\nERROR: Incorrect readback of Word-16 at addr %lx from Rx Mem: %x, expected: %lx \n", addr, rxMem16[addr/2], val >> 48);
            exit(1);
          }
          if ((addr%4) == 3 && rxMem32[addr/4] != (val >> 32)) {
            printf("\nERROR: Incorrect readback of Word-32 at addr %lx from Rx Mem: %x, expected: %lx \n", addr, rxMem32[addr/4], val >> 32);
            exit(1);
          }
          if ((addr%8) == 7 && rxMem64[addr/8] !=  val)        {
            printf("\nERROR: Incorrect readback of Word-64 at addr %lx from Rx Mem: %lx, expected: %lx \n", addr, rxMem64[addr/8], val);
            exit(1);
          }
        }
        printf("Checking BD memory at addr 0x%lX(virt: 0x%lX) with size %ld \n", ETH_SYST_BASEADDR+SG_MEM_CPU_BASEADDR, size_t(ethSyst.sgMem), sgMemSize);
        for (size_t addr = 0; addr < sgMemSize; ++addr) {
          uint64_t rand64 = rand();
          val = (val >> 8) | (rand64 << 56);
          // checking readback using different data types
          if (                 sgMem8 [addr  ] != (val >> 56)) {
            printf("\nERROR: Incorrect readback of Byte at addr %lx from BD Mem: %x, expected: %lx \n", addr, sgMem8[addr], val >> 56);
            exit(1);
          }
          if ((addr%2) == 1 && sgMem16[addr/2] != (val >> 48)) {
            printf("\nERROR: Incorrect readback of Word-16 at addr %lx from BD Mem: %x, expected: %lx \n", addr, sgMem16[addr/2], val >> 48);
            exit(1);
          }
          if ((addr%4) == 3 && sgMem32[addr/4] != (val >> 32)) {
            printf("\nERROR: Incorrect readback of Word-32 at addr %lx from BD Mem: %x, expected: %lx \n", addr, sgMem32[addr/4], val >> 32);
            exit(1);
          }
          if ((addr%8) == 7 && sgMem64[addr/8] !=  val)        {
            printf("\nERROR: Incorrect readback of Word-64 at addr %lx from BD Mem: %lx, expected: %lx \n", addr, sgMem64[addr/8], val);
            exit(1);
          }
        }
        printf("------- DMA Tx/Rx/SG memory test PASSED -------\n\n");

        ethSyst.axiDmaInit();

        printf("------- Running DMA Short Loopback test -------\n");
        ethSyst.switch_LB_DMA_Eth(true,  true); // Tx switch: DMA->LB, LB->Eth
        ethSyst.switch_LB_DMA_Eth(false, true); // Rx switch: LB->DMA, Eth->LB
        sleep(1); // in seconds

        srand(1);
        for (size_t addr = 0; addr < txMemWords; ++addr) ethSyst.txMem[addr] = rand();
        for (size_t addr = 0; addr < rxMemWords; ++addr) ethSyst.rxMem[addr] = 0;

        size_t packets = txrxMemSize/DMA_PACKET_LEN;
        if (XAxiDma_HasSg(&ethSyst.axiDma))
          packets = std::min(packets,
                    std::min(ethSyst.txBdCount,
                             ethSyst.rxBdCount));
        printf("DMA: Transferring %ld whole packets with length %d bytes between memories with common size %ld bytes \n",
                    packets, DMA_PACKET_LEN, txrxMemSize);
        size_t dmaTxMemPtr = size_t(ethSyst.TX_DMA_MEM_ADDR);
        size_t dmaRxMemPtr = size_t(ethSyst.RX_DMA_MEM_ADDR);
        if (XAxiDma_HasSg(&ethSyst.axiDma)) {
          XAxiDma_Bd* rxBdPtr = ethSyst.dmaBDAlloc(true,  packets, DMA_PACKET_LEN, DMA_PACKET_LEN, dmaRxMemPtr); // Rx
          XAxiDma_Bd* txBdPtr = ethSyst.dmaBDAlloc(false, packets, DMA_PACKET_LEN, DMA_PACKET_LEN, dmaTxMemPtr); // Tx
          ethSyst.dmaBDTransfer                   (true,  packets, packets,        rxBdPtr); // Rx
          ethSyst.dmaBDTransfer                   (false, packets, packets,        txBdPtr); // Tx
          txBdPtr             = ethSyst.dmaBDPoll (false, packets); // Tx
          rxBdPtr             = ethSyst.dmaBDPoll (true,  packets); // Rx
          ethSyst.dmaBDFree                       (false, packets, DMA_PACKET_LEN, txBdPtr); // Tx
          ethSyst.dmaBDFree                       (true,  packets, DMA_PACKET_LEN, rxBdPtr); // Rx

          uint32_t transDat = packets * DMA_PACKET_LEN;
          float txTime = XTmrCtr_GetValue(&ethSyst.timerCnt, 0) * ethSyst.TIMER_TICK;
          float rxTime = XTmrCtr_GetValue(&ethSyst.timerCnt, 1) * ethSyst.TIMER_TICK;
          float txSpeed = (transDat * 8) / txTime;
          float rxSpeed = (transDat * 8) / rxTime;
          printf("Transfer: %d Bytes \n", transDat);
          printf("Tx time: %f ns, Speed: %f Gb/s \n", txTime, txSpeed);
          printf("Rx time: %f ns, Speed: %f Gb/s \n", rxTime, rxSpeed);

        }
        else for (size_t packet = 0; packet < packets; packet++) {
		      int status = XAxiDma_SimpleTransfer(&(ethSyst.axiDma), dmaRxMemPtr, DMA_PACKET_LEN, XAXIDMA_DEVICE_TO_DMA);
         	if (XST_SUCCESS != status) {
            printf("\nERROR: XAxiDma Rx transfer %ld failed with status %d\n", packet, status);
            exit(1);
	        }
		      status = XAxiDma_SimpleTransfer(&(ethSyst.axiDma), dmaTxMemPtr, DMA_PACKET_LEN, XAXIDMA_DMA_TO_DEVICE);
         	if (XST_SUCCESS != status) {
            printf("\nERROR: XAxiDma Tx transfer %ld failed with status %d\n", packet, status);
            exit(1);
	        }
		      while ((XAxiDma_Busy(&(ethSyst.axiDma),XAXIDMA_DEVICE_TO_DMA)) ||
			           (XAxiDma_Busy(&(ethSyst.axiDma),XAXIDMA_DMA_TO_DEVICE))) {
            // printf("Waiting untill last Tx/Rx transfer finishes \n");
            // sleep(1); // in seconds, user wait process
          }
          dmaTxMemPtr += DMA_PACKET_LEN;
          dmaRxMemPtr += DMA_PACKET_LEN;
    		}

        for (size_t addr = 0; addr < (packets * DMA_PACKET_LEN)/sizeof(uint32_t); ++addr) {
          if (ethSyst.rxMem[addr] != ethSyst.txMem[addr]) {
            printf("\nERROR: Incorrect data transferred by DMA at addr %ld: %0X, expected: %0X \n", addr, ethSyst.rxMem[addr], ethSyst.txMem[addr]);
            exit(1);
          }
        }
        printf("------- DMA Short Loopback test PASSED -------\n\n");

        ethSyst.ethCoreInit(true);

        printf("------- Running DMA Near-end loopback test -------\n");
        ethSyst.switch_LB_DMA_Eth(true,  false); // Tx switch: DMA->Eth, Eth LB->DMA LB
        ethSyst.switch_LB_DMA_Eth(false, false); // Rx switch: Eth->DMA, DMA LB->Eth LB
        sleep(1); // in seconds

        srand(1);
        for (size_t addr = 0; addr < txMemWords; ++addr) ethSyst.txMem[addr] = rand();
        for (size_t addr = 0; addr < rxMemWords; ++addr) ethSyst.rxMem[addr] = 0;

        ethSyst.ethTxRxEnable(); // Enabling Ethernet TX/RX

        packets = txrxMemSize/ETH_MEMPACK_SIZE;
        if (XAxiDma_HasSg(&ethSyst.axiDma))
          packets = std::min(packets,
                    std::min(ethSyst.txBdCount,
                             ethSyst.rxBdCount));
        size_t txBunch = ETH_PACKET_LEN > ETH_WORD_SIZE*4 ? 1 : packets; // whole bunch Tx kick-off for small packets
        printf("DMA: Transferring %ld whole packets with length %d bytes between memories with common size %ld bytes (packet allocation %d bytes) \n",
                    packets, ETH_PACKET_LEN, txrxMemSize, ETH_MEMPACK_SIZE);
        dmaTxMemPtr = size_t(ethSyst.TX_DMA_MEM_ADDR);
        dmaRxMemPtr = size_t(ethSyst.RX_DMA_MEM_ADDR);
        if (XAxiDma_HasSg(&ethSyst.axiDma)) {
          XAxiDma_Bd* rxBdPtr = ethSyst.dmaBDAlloc(true,  packets, ETH_PACKET_LEN, ETH_MEMPACK_SIZE, dmaRxMemPtr); // Rx
          XAxiDma_Bd* txBdPtr = ethSyst.dmaBDAlloc(false, packets, ETH_PACKET_LEN, ETH_MEMPACK_SIZE, dmaTxMemPtr); // Tx
          ethSyst.dmaBDTransfer                   (true,  packets, packets,        rxBdPtr); // Rx
          ethSyst.dmaBDTransfer                   (false, packets, txBunch,        txBdPtr); // Tx, each packet kick-off for big packets
          txBdPtr             = ethSyst.dmaBDPoll (false, packets); // Tx
          rxBdPtr             = ethSyst.dmaBDPoll (true,  packets); // Rx
          ethSyst.dmaBDFree                       (false, packets, ETH_PACKET_LEN, txBdPtr); // Tx
          ethSyst.dmaBDFree                       (true,  packets, ETH_PACKET_LEN, rxBdPtr); // Rx

          uint32_t transDat = packets * ETH_PACKET_LEN;
          float txTime = XTmrCtr_GetValue(&ethSyst.timerCnt, 0) * ethSyst.TIMER_TICK;
          float rxTime = XTmrCtr_GetValue(&ethSyst.timerCnt, 1) * ethSyst.TIMER_TICK;
          float txSpeed = (transDat * 8) / txTime;
          float rxSpeed = (transDat * 8) / rxTime;
          printf("Transfer: %d Bytes \n", transDat);
          printf("Tx time: %f ns, Speed: %f Gb/s \n", txTime, txSpeed);
          printf("Rx time: %f ns, Speed: %f Gb/s \n", rxTime, rxSpeed);
        }
        else for (size_t packet = 0; packet < packets; packet++) {
          int status = XAxiDma_SimpleTransfer(&(ethSyst.axiDma), dmaRxMemPtr, ETH_PACKET_LEN, XAXIDMA_DEVICE_TO_DMA);
          if (XST_SUCCESS != status) {
            printf("\nERROR: XAxiDma Rx transfer %ld failed with status %d\n", packet, status);
            exit(1);
          }
          status = XAxiDma_SimpleTransfer(&(ethSyst.axiDma), dmaTxMemPtr, ETH_PACKET_LEN, XAXIDMA_DMA_TO_DEVICE);
          if (XST_SUCCESS != status) {
            printf("\nERROR: XAxiDma Tx transfer %ld failed with status %d\n", packet, status);
            exit(1);
          }
          while ((XAxiDma_Busy(&(ethSyst.axiDma),XAXIDMA_DEVICE_TO_DMA)) ||
                 (XAxiDma_Busy(&(ethSyst.axiDma),XAXIDMA_DMA_TO_DEVICE))) {
            // printf("Waiting untill Tx/Rx transfer finishes \n");
            // sleep(1); // in seconds, user wait process
          }
          dmaTxMemPtr += ETH_MEMPACK_SIZE;
          dmaRxMemPtr += ETH_MEMPACK_SIZE;
        }

        for (size_t packet = 0; packet < packets; packet++)
        for (size_t word   = 0; word < ETH_MEMPACK_SIZE/sizeof(uint32_t); word++) {
          size_t addr = packet*ETH_MEMPACK_SIZE/sizeof(uint32_t) + word;
          if (word < ETH_PACKET_LEN/sizeof(uint32_t)) {
            if (ethSyst.rxMem[addr] != ethSyst.txMem[addr]) {
              printf("\nERROR: Incorrect data transferred by DMA in 32-bit word %ld of packet %ld at addr %ld: %0X, expected: %0X \n",
                          word, packet, addr, ethSyst.rxMem[addr], ethSyst.txMem[addr]);
              exit(1);
            }
          }
          else if (word == ETH_PACKET_LEN/sizeof(uint32_t)) {
            uint32_t expectVal = ethSyst.txMem[addr] & ((1<<(8*(ETH_PACKET_LEN%sizeof(uint32_t))))-1);
            if (ethSyst.rxMem[addr] != expectVal) {
              printf("\nERROR: Incorrect data transferred by DMA in last 32-bit word %ld of packet %ld at addr %ld: %0X, expected: %0X \n",
                          word, packet, addr, ethSyst.rxMem[addr], expectVal);
              exit(1);
            }
          }
          else if (ethSyst.rxMem[addr] != 0) {
              printf("\nERROR: Data in 32-bit word %ld of packet %ld overwrite stored zero at addr %ld: %0X \n",
                         word, packet, addr, ethSyst.rxMem[addr]);
              exit(1);
          }
        }

        ethSyst.ethTxRxDisable(); //Disabling Ethernet TX/RX
        printf("------- DMA Near-end loopback test PASSED -------\n\n");

      }
      break;


      case 'c': {
        printf("------- Running 2-boards communication test -------\n");
        printf("Please make sure that the same mode is running on the other side and confirm with 'y'...\n");
        char confirm;
        scanf("%s", &confirm);
        printf("%c\n", confirm);
        if (confirm != 'y') break;

        ethSyst.ethCoreInit(false);
        //resetting BD memory to probably flush its cache before BD ring initialization, not needed anymore
        // for (size_t addr = 0; addr < sgMemWords; ++addr) ethSyst.sgMem[addr] = 0;
        ethSyst.axiDmaInit();

        printf("------- Async DMA 2-boards communication test -------\n");
        ethSyst.switch_LB_DMA_Eth(true,  false); // Tx switch: DMA->Eth, Eth LB->DMA LB
        ethSyst.switch_LB_DMA_Eth(false, false); // Rx switch: Eth->DMA, DMA LB->Eth LB
        sleep(1); // in seconds

        srand(1);
        for (size_t addr = 0; addr < txMemWords; ++addr) ethSyst.txMem[addr] = rand();
        for (size_t addr = 0; addr < rxMemWords; ++addr) ethSyst.rxMem[addr] = 0;

        ethSyst.ethTxRxEnable(); // Enabling Ethernet TX/RX

        size_t packets = txrxMemSize/ETH_MEMPACK_SIZE;
        if (XAxiDma_HasSg(&ethSyst.axiDma))
          packets = std::min(packets,
                    std::min(ethSyst.txBdCount,
                             ethSyst.rxBdCount));
        size_t txBunch = ETH_PACKET_LEN > ETH_WORD_SIZE*4 ? 1 : packets; // whole bunch Tx kick-off for small packets
        printf("DMA: Transferring %ld whole packets with length %d bytes between memories with common size %ld bytes (packet allocation %d bytes) \n",
                    packets, ETH_PACKET_LEN, txrxMemSize, ETH_MEMPACK_SIZE);
        size_t dmaTxMemPtr = size_t(ethSyst.TX_DMA_MEM_ADDR);
        size_t dmaRxMemPtr = size_t(ethSyst.RX_DMA_MEM_ADDR);
        if (XAxiDma_HasSg(&ethSyst.axiDma)) {
          XAxiDma_Bd* rxBdPtr = ethSyst.dmaBDAlloc(true,  packets, ETH_PACKET_LEN, ETH_MEMPACK_SIZE, dmaRxMemPtr); // Rx
          XAxiDma_Bd* txBdPtr = ethSyst.dmaBDAlloc(false, packets, ETH_PACKET_LEN, ETH_MEMPACK_SIZE, dmaTxMemPtr); // Tx
          ethSyst.dmaBDTransfer                   (true,  packets, packets,        rxBdPtr); // Rx
          sleep(3); // in seconds, timeout before Tx transfer to make sure opposite side also has set Rx transfer
          ethSyst.dmaBDTransfer                   (false, packets, txBunch,        txBdPtr); // Tx, each packet kick-off for big packets
          txBdPtr             = ethSyst.dmaBDPoll (false, packets); // Tx
          rxBdPtr             = ethSyst.dmaBDPoll (true,  packets); // Rx
          ethSyst.dmaBDFree                       (false, packets, ETH_PACKET_LEN, txBdPtr); // Tx
          ethSyst.dmaBDFree                       (true,  packets, ETH_PACKET_LEN, rxBdPtr); // Rx

          uint32_t transDat = packets * ETH_PACKET_LEN;
          float txTime = XTmrCtr_GetValue(&ethSyst.timerCnt, 0) * ethSyst.TIMER_TICK;
          float rxTime = XTmrCtr_GetValue(&ethSyst.timerCnt, 1) * ethSyst.TIMER_TICK;
          float txSpeed = (transDat * 8) / txTime;
          float rxSpeed = (transDat * 8) / rxTime;
          printf("Transfer: %d Bytes \n", transDat);
          printf("Tx time: %f ns, Speed: %f Gb/s \n", txTime, txSpeed);
          if (0) printf("Rx time: %f ns, Speed: %f Gb/s \n", rxTime, rxSpeed); // meaningless here
        }
        else for (size_t packet = 0; packet < packets; packet++) {
          int status = XAxiDma_SimpleTransfer(&(ethSyst.axiDma), dmaRxMemPtr, ETH_PACKET_LEN, XAXIDMA_DEVICE_TO_DMA);
          if (XST_SUCCESS != status) {
            printf("\nERROR: XAxiDma Rx transfer %ld failed with status %d\n", packet, status);
            exit(1);
          }
          if (packet == 0) sleep(1); // in seconds, timeout before 1st packet Tx transfer to make sure opposite side also has set Rx transfer
          status = XAxiDma_SimpleTransfer(&(ethSyst.axiDma), dmaTxMemPtr, ETH_PACKET_LEN, XAXIDMA_DMA_TO_DEVICE);
          if (XST_SUCCESS != status) {
            printf("\nERROR: XAxiDma Tx transfer %ld failed with status %d\n", packet, status);
            exit(1);
          }
          while ((XAxiDma_Busy(&(ethSyst.axiDma),XAXIDMA_DEVICE_TO_DMA)) ||
                 (XAxiDma_Busy(&(ethSyst.axiDma),XAXIDMA_DMA_TO_DEVICE))) {
            // printf("Waiting untill Tx/Rx transfer finishes \n");
            // sleep(1); // in seconds, user wait process
          }
          dmaTxMemPtr += ETH_MEMPACK_SIZE;
          dmaRxMemPtr += ETH_MEMPACK_SIZE;
        }

        for (size_t packet = 0; packet < packets; packet++)
        for (size_t word   = 0; word < ETH_MEMPACK_SIZE/sizeof(uint32_t); word++) {
          size_t addr = packet*ETH_MEMPACK_SIZE/sizeof(uint32_t) + word;
          if (word < ETH_PACKET_LEN/sizeof(uint32_t)) {
            if (ethSyst.rxMem[addr] != ethSyst.txMem[addr]) {
              printf("\nERROR: Incorrect data transferred by DMA in 32-bit word %ld of packet %ld at addr %ld: %0X, expected: %0X \n",
                          word, packet, addr, ethSyst.rxMem[addr], ethSyst.txMem[addr]);
              exit(1);
            }
          }
          else if (word == ETH_PACKET_LEN/sizeof(uint32_t)) {
            uint32_t expectVal = ethSyst.txMem[addr] & ((1<<(8*(ETH_PACKET_LEN%sizeof(uint32_t))))-1);
            if (ethSyst.rxMem[addr] != expectVal) {
              printf("\nERROR: Incorrect data transferred by DMA in last 32-bit word %ld of packet %ld at addr %ld: %0X, expected: %0X \n",
                          word, packet, addr, ethSyst.rxMem[addr], expectVal);
              exit(1);
            }
          }
          else if (ethSyst.rxMem[addr] != 0) {
              printf("\nERROR: Data in 32-bit word %ld of packet %ld overwrite stored zero at addr %ld: %0X \n",
                          word, packet, addr, ethSyst.rxMem[addr]);
              exit(1);
          }
        }

        ethSyst.ethTxRxDisable(); //Disabling Ethernet TX/RX
        printf("------- Async DMA 2-boards communication test PASSED -------\n\n");


        printf("------- Round-trip DMA 2-boards communication test -------\n");
        ethSyst.switch_LB_DMA_Eth(true,  false); // Tx switch: DMA->Eth, Eth LB->DMA LB
        ethSyst.switch_LB_DMA_Eth(false, false); // Rx switch: Eth->DMA, DMA LB->Eth LB
        sleep(1); // in seconds

        srand(1);
        for (size_t addr = 0; addr < txMemWords; ++addr) ethSyst.txMem[addr] = rand();
        for (size_t addr = 0; addr < rxMemWords; ++addr) ethSyst.rxMem[addr] = 0;

        ethSyst.ethTxRxEnable(); // Enabling Ethernet TX/RX

        packets = txrxMemSize/ETH_MEMPACK_SIZE;
        if (XAxiDma_HasSg(&ethSyst.axiDma))
          packets = std::min(packets,
                    std::min(ethSyst.txBdCount,
                             ethSyst.rxBdCount));
        txBunch = ETH_PACKET_LEN > ETH_WORD_SIZE*4 ? 1 : packets; // whole bunch Tx kick-off for small packets
        printf("DMA: Transferring %ld whole packets with length %d bytes between memories with common size %ld bytes (packet allocation %d bytes) \n",
                    packets, ETH_PACKET_LEN, txrxMemSize, ETH_MEMPACK_SIZE);
        dmaTxMemPtr = size_t(ethSyst.TX_DMA_MEM_ADDR);
        dmaRxMemPtr = size_t(ethSyst.RX_DMA_MEM_ADDR);
        if (XAxiDma_HasSg(&ethSyst.axiDma)) {
          XAxiDma_Bd* rxBdPtr = ethSyst.dmaBDAlloc(true,  packets, ETH_PACKET_LEN, ETH_MEMPACK_SIZE, dmaRxMemPtr); // Rx
          XAxiDma_Bd* txBdPtr = ethSyst.dmaBDAlloc(false, packets, ETH_PACKET_LEN, ETH_MEMPACK_SIZE, dmaTxMemPtr); // Tx
          ethSyst.dmaBDTransfer                   (true,  packets, packets,        rxBdPtr); // Rx
          if (ethSyst.physConnOrder) { // depending on board instance play "initiator" role
            printf("Initiator side: starting the transfer and receiving it back \n");
            sleep(3); // in seconds, timeout before Tx transfer to make sure opposite side also has set Rx transfer
            ethSyst.dmaBDTransfer                 (false, packets, txBunch,        txBdPtr); // Tx, each packet kick-off for big packets
            txBdPtr           = ethSyst.dmaBDPoll (false, packets); // Tx
            rxBdPtr           = ethSyst.dmaBDPoll (true,  packets); // Rx
          } else { // depending on board instance play "responder" role
            printf("Responder side: accepting the transfer and sending it back \n");
            rxBdPtr           = ethSyst.dmaBDPoll (true,  packets); // Rx
            ethSyst.dmaBDTransfer                 (false, packets, txBunch,        txBdPtr); // Tx, each packet kick-off for big packets
            txBdPtr           = ethSyst.dmaBDPoll (false, packets); // Tx
          }
          ethSyst.dmaBDFree                       (false, packets, ETH_PACKET_LEN, txBdPtr); // Tx
          ethSyst.dmaBDFree                       (true,  packets, ETH_PACKET_LEN, rxBdPtr); // Rx
          uint32_t transDat = packets * ETH_PACKET_LEN;
          float txTime = XTmrCtr_GetValue(&ethSyst.timerCnt, 0) * ethSyst.TIMER_TICK;
          float rxTime = XTmrCtr_GetValue(&ethSyst.timerCnt, 1) * ethSyst.TIMER_TICK;
          float txSpeed = (    transDat * 8) / txTime;
          float rxSpeed = (2 * transDat * 8) / rxTime; //transfer is doubled due to round-trip
          printf("Transfer: %d Bytes \n", transDat);
          printf("Tx time: %f ns, Speed: %f Gb/s \n", txTime, txSpeed);
          if (ethSyst.physConnOrder) printf("Rx time: %f ns, Speed: %f Gb/s \n", rxTime, rxSpeed);
        }
        else {
          printf("For Simple DMA mode no Round-trip exchange is done, Asynch exchange is executed instead \n");
          for (size_t packet = 0; packet < packets; packet++) {
          int status = XAxiDma_SimpleTransfer(&(ethSyst.axiDma), dmaRxMemPtr, ETH_PACKET_LEN, XAXIDMA_DEVICE_TO_DMA);
          if (XST_SUCCESS != status) {
            printf("\nERROR: XAxiDma Rx transfer %ld failed with status %d\n", packet, status);
            exit(1);
          }
          if (packet == 0) sleep(1); // in seconds, timeout before 1st packet Tx transfer to make sure opposite side also has set Rx transfer
          status = XAxiDma_SimpleTransfer(&(ethSyst.axiDma), dmaTxMemPtr, ETH_PACKET_LEN, XAXIDMA_DMA_TO_DEVICE);
          if (XST_SUCCESS != status) {
            printf("\nERROR: XAxiDma Tx transfer %ld failed with status %d\n", packet, status);
            exit(1);
          }
          while ((XAxiDma_Busy(&(ethSyst.axiDma),XAXIDMA_DEVICE_TO_DMA)) ||
                 (XAxiDma_Busy(&(ethSyst.axiDma),XAXIDMA_DMA_TO_DEVICE))) {
            // printf("Waiting untill Tx/Rx transfer finishes \n");
            // sleep(1); // in seconds, user wait process
          }
          dmaTxMemPtr += ETH_MEMPACK_SIZE;
          dmaRxMemPtr += ETH_MEMPACK_SIZE;
          }
        }

        for (size_t packet = 0; packet < packets; packet++)
        for (size_t word   = 0; word < ETH_MEMPACK_SIZE/sizeof(uint32_t); word++) {
          size_t addr = packet*ETH_MEMPACK_SIZE/sizeof(uint32_t) + word;
          if (word < ETH_PACKET_LEN/sizeof(uint32_t)) {
            if (ethSyst.rxMem[addr] != ethSyst.txMem[addr]) {
              printf("\nERROR: Incorrect data transferred by DMA in 32-bit word %ld of packet %ld at addr %ld: %0X, expected: %0X \n",
                          word, packet, addr, ethSyst.rxMem[addr], ethSyst.txMem[addr]);
              exit(1);
            }
          }
          else if (word == ETH_PACKET_LEN/sizeof(uint32_t)) {
            uint32_t expectVal = ethSyst.txMem[addr] & ((1<<(8*(ETH_PACKET_LEN%sizeof(uint32_t))))-1);
            if (ethSyst.rxMem[addr] != expectVal) {
              printf("\nERROR: Incorrect data transferred by DMA in last 32-bit word %ld of packet %ld at addr %ld: %0X, expected: %0X \n",
                          word, packet, addr, ethSyst.rxMem[addr], expectVal);
              exit(1);
            }
          }
          else if (ethSyst.rxMem[addr] != 0) {
              printf("\nERROR: Data in 32-bit word %ld of packet %ld overwrite stored zero at addr %ld: %0X \n",
                          word, packet, addr, ethSyst.rxMem[addr]);
              exit(1);
          }
        }

        ethSyst.ethTxRxDisable(); //Disabling Ethernet TX/RX
        printf("------- Round-trip DMA 2-boards communication test PASSED -------\n\n");
      }
      break;


      case 'i': {
        printf("------- Running 2-boards IP-based tests -------\n");
        printf("Please make sure that the same mode is running on the other side and confirm with 'y'...\n");
        char confirm;
        scanf("%s", &confirm);
        printf("%c\n", confirm);
        if (confirm != 'y') break;

        ethSyst.ethCoreInit(false); // non-loopback mode
        printf("\n------- Physical connection is established -------\n");

        while (true) {
          ethSyst.ethSystInit(); // resetting hardware before any test
          printf("\n------- Please choose particular IP-based test:\n");
          printf("  Ping reply   test:       p\n");
          printf("  Ping request test:       q\n");
          printf("  LwIP UDP Server (empty): u\n");
          printf("  LwIP UDP Client (empty): d\n");
          printf("  LwIP TCP Server (empty): t\n");
          printf("  LwIP TCP Client (empty): c\n");
          printf("  Exit to main menu:       e\n");
          char choice;
          scanf("%s", &choice);
          printf("You have entered: %c\n\n", choice);

          switch (choice) {
            case 'p': {
              printf("------- Ping Reply test -------\n");
              PingReplyTest pingReplyTest(&ethSyst);
              int status = pingReplyTest.pingReply();
              if (status != XST_SUCCESS) {
                printf("\nERROR: Ping Reply test failed with status %d\n", status);
                exit(1);
              }
              printf("------- Ping Reply test finished -------\n\n");
            }
            break;

            case 'q': {
              printf("------- Ping Request test -------\n");
              PingReqstTest pingReqstTest(&ethSyst);
            	int status = pingReqstTest.pingReqst();
	            if (status != XST_SUCCESS) {
		            printf("\nERROR: Ping Request test failed with status %d\n", status);
                exit(1);
	            }
              printf("------- Ping Request test finished -------\n\n");
            }
            break;

            case 'u': {
              printf("------- LwIP UDP Perf Server -------\n");
            	// int status = udp_perf_server();
	            // if (status != XST_SUCCESS) {
		          //   printf("\nERROR: LwIP UDP Perf Server failed with status %d\n", status);
              //   exit(1);
	            // }
              printf("------- LwIP UDP Perf Server finished -------\n\n");
            }
            break;

            case 'd': {
              printf("------- LwIP UDP Perf Client -------\n");
            	// int status = udp_perf_client();
	            // if (status != XST_SUCCESS) {
		          //   printf("\nERROR: LwIP UDP Perf Client failed with status %d\n", status);
              //   exit(1);
	            // }
              printf("------- LwIP UDP Perf Client finished -------\n\n");
            }
            break;

            case 't': {
              printf("------- LwIP TCP Perf Server -------\n");
            	// int status = tcp_perf_server();
	            // if (status != XST_SUCCESS) {
		          //   printf("\nERROR: LwIP TCP Perf Server failed with status %d\n", status);
              //   exit(1);
	            // }
              printf("------- LwIP TCP Perf Server finished -------\n\n");
            }
            break;

            case 'c': {
              printf("------- LwIP TCP Perf Client -------\n");
            	// int status = tcp_perf_client();
	            // if (status != XST_SUCCESS) {
		          //   printf("\nERROR: LwIP TCP Perf Client failed with status %d\n", status);
              //   exit(1);
	            // }
              printf("------- LwIP TCP Perf Client finished -------\n\n");
            }
            break;

            case 'e':
              printf("------- Exiting to main menu -------\n");
              break;

            default: printf("Please choose right option\n");
          }
          if (choice == 'e') break;
        }

        ethSyst.ethTxRxDisable();
      }
      break;

      case 'f':
        printf("------- Exiting the app -------\n");
        return(0);

      default: printf("Please choose right option\n");
    }
  }
}
