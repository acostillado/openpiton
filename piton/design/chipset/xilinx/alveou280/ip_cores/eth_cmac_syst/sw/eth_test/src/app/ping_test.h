/*****************************************************************************/
/**
* @file Initially started from Xilinx xemaclite_ping_req_example.c
* @file Initially started from Xilinx xemaclite_ping_reply_example.c
*
* Copyright (C) 2008 - 2020 Xilinx, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
*****************************************************************************/

#ifndef PINGTEST_H  // prevent circular inclusions
#define PINGTEST_H  // by using protection macros


//***************************** Include Files *********************************
#include "EthSyst.h"
#include "eth_defs.h"

//*********** Ping Request Class *************
class PingReqstTest {
  // User Test run definitions
  enum {
    NUM_OF_PING_REQ_PKTS   = 11,    // Number of ping req it generates, change this parameter to limit the number of ping requests sent by this program.
    NUM_RX_PACK_CHECK_REQ  = 10,    // Max num of Rx pack to be checked before sending another request
    NUM_PACK_CHECK_RX_PACK = 100000 // Max number of pack to be checked before to identify a Rx packet
  };

  // Set up a local MAC address.
  uint8_t  LocalMacAddr[MAC_ADDR_LEN * sizeof(uint16_t)] = {0x00, 0x0A, 0x35, 0x00, 0x01, 0x02};
  uint16_t DestMacAddr [MAC_ADDR_LEN]; // Destination MAC Address

  // The IP addresses. User need to set a free IP address based on the network on which this example is to be run.
  uint8_t LocalIpAddr[IP_ADDR_SIZE] = {192, 168, 1, 10 };
  uint8_t DestIpAddr [IP_ADDR_SIZE] = {192, 168, 1, 100}; // Set up a Destination IP address.

  // Known data transmitted in Echo request.
  uint16_t IcmpData[ICMP_KNOWN_DATA_LEN] = {
    0x6162, 0x6364, 0x6566, 0x6768, 0x696A, 0x6B6C, 0x6D6E, 0x6F70,
    0x7172, 0x7374, 0x7576, 0x7761, 0x6263, 0x6465, 0x6667, 0x6869
  };

  // IP header information -- each field has its own significance.
  // Icmp type, ipv4 typelength, packet length, identification field, Fragment type, time to live and ICM, checksum.
  uint16_t IpHeaderInfo[IP_HEADER_INFO_LEN] = {0x0800, 0x4500, 0x003C, 0x5566, 0x0000, 0x8001, 0x0000};

  // Buffers used for Transmission and Reception of Packets.
  uint8_t RxFrame[XAE_MAX_FRAME_SIZE];
  uint8_t TxFrame[XAE_MAX_FRAME_SIZE];

  int SeqNum; // Variable used to indicate the sequence number of the ICMP(echo) packet.
  int NumOfPingReqPkts; // Variable used to indicate the number of ping request packets to be send.

  void SendEchoReqFrame();
  void SendArpReqFrame();
  int ProcessRcvFrame();

  EthSyst* ethSystPtr; // Ethernet System hardware

  public:
  PingReqstTest(EthSyst*);
  int pingReqst();
};


//*********** Ping Reply Class *************
class PingReplyTest {
  // User Test run definitions
  enum {
    MAX_PING_REPLIES = 10 // Maximum number of ping replies, change this parameter to limit the number of ping replies sent by this program.
  };

  // Set up a local MAC address.
  uint8_t LocalMacAddr[MAC_ADDR_LEN * sizeof(uint16_t)] = {0x00, 0x0A, 0x35, 0x03, 0x02, 0x01};

  // The IP address. User need to set a free IP address based on the network on which this example is to be run.
  uint8_t LocalIpAddr[IP_ADDR_SIZE] = {192, 168, 1, 100};

  // Buffers used for Transmission and Reception of Packets.
  uint8_t RxFrame[XAE_MAX_FRAME_SIZE];
  uint8_t TxFrame[XAE_MAX_FRAME_SIZE];

  uint32_t NumOfPingReplies; // Variable used to indicate the number of Ping replies sent.

  void ProcessRcvFrame();

  EthSyst* ethSystPtr; // Ethernet System hardware

  public:
  PingReplyTest(EthSyst*);
  int pingReply();
};

#endif // end of protection macro
