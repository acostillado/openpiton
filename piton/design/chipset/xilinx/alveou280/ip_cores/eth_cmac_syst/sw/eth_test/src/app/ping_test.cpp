//***************************** Include Files *********************************
#include <stdio.h>
#include <unistd.h>

#include "ping_test.h"


//*********** Ping Request Class *************
/**
* Initially started from Xilinx xemaclite_ping_req_example.c
*
* Copyright (C) 2008 - 2020 Xilinx, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
*
* This file contains a EmacLite Ping request example in polled mode. This
* example will generate a ping request for the specified IP address.
*
* @note
*
* The local IP address is set to 172.16.63.121. User needs to update
* LocalIpAddr variable with a free IP address based on the network on which
* this example is to be run.
*
* The Destination IP address is set to 172.16.63.61. User needs to update
* DestIpAddr variable with any valid IP address based on the network on which
* this example is to be run.
*
* The local MAC address is set to 0x000A35030201. User can update LocalMacAddr
* variable with a valid MAC address. The first three bytes contains
* the manufacture ID. 0x000A35 is XILINX manufacture ID.
*
* This program will generate the specified number of ping request packets as
* defined in "NUM_OF_PING_REQ_PKTS".
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a ktn  27/08/08 First release
* 3.00a ktn  10/22/09 Updated example to use the macros that have been changed
*		      in the driver to remove _m from the name of the macro.
* 3.01a ktn  08/06/10 Updated the example to support little endian MicroBlaze.
* 4.3   ms   01/23/17 Added xil_printf statement in main function to
*                     ensure that "Successfully ran" and "Failed" strings
*                     are available in all examples. This is a fix for
*                     CR-965028.
*
* </pre>
*
*****************************************************************************/

//*********** Ping Request Constructor *************
PingReqstTest::PingReqstTest(EthSyst* _ethSystPtr_) {
  ethSystPtr = _ethSystPtr_;
}


/*****************************************************************************/
/**
*
* This function calculates the checksum and returns a 16 bit result.
*
* @param 	RxFramePtr is a 16 bit pointer for the data to which checksum
* 		is to be calculated.
* @param	StartLoc is the starting location of the data from which the
*		checksum has to be calculated.
* @param	Length is the number of halfwords(16 bits) to which checksum is
* 		to be calculated.
*
* @return	It returns a 16 bit checksum value.
*
* @note		This can also be used for calculating checksum. The ones
* 		complement of this return value will give the final checksum.
*
******************************************************************************/
uint16_t CheckSumCalculation(uint16_t* RxFramePtr, int StartLoc, int Length)
{
	uint32_t Sum = 0;
	uint16_t CheckSum = 0;
	int Index;

	/*
	 * Add all the 16 bit data.
	 */
	Index = StartLoc;
	while (Index < (StartLoc + Length)) {
		Sum = Sum + Xil_Htons(*(RxFramePtr + Index));
		Index++;
	}

	/*
	 * Add upper 16 bits to lower 16 bits.
	 */
	CheckSum = Sum;
	Sum = Sum >> 16;
	CheckSum = Sum + CheckSum;
	return CheckSum;
}


/*****************************************************************************/
/**
*
* This function will send a Echo request packet.
*
* @param	InstancePtr is a pointer to the instance of the EmacLite.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void PingReqstTest::SendEchoReqFrame()
{
	uint16_t* TempPtr;
	uint16_t* TxFramePtr;
	uint16_t  CheckSum;
	int Index;

	TxFramePtr = (uint16_t*)TxFrame;

	/*
	 * Add Destination MAC Address.
	 */
	Index = MAC_ADDR_LEN;
	while (Index--) {
		*(TxFramePtr + Index) = *(DestMacAddr + Index);
	}

	/*
	 * Add Source MAC Address.
	 */
	Index = MAC_ADDR_LEN;
	TempPtr = (uint16_t*)LocalMacAddr;
	while (Index--) {
		*(TxFramePtr + (Index + SRC_MAC_ADDR_LOC )) =
							*(TempPtr + Index);
	}

	/*
	 * Add IP header information.
	 */
	Index = IP_HDR_START_LOC;
	while (Index--) {
		*(TxFramePtr + (Index + ETHER_PROTO_TYPE_LOC )) =
				Xil_Htons(*(IpHeaderInfo + Index));
	}

	/*
	 * Add Source IP address.
	 */
	Index = IP_ADDR_LEN;
	TempPtr = (uint16_t*)LocalIpAddr;
	while (Index--) {
		*(TxFramePtr + (Index + IP_REQ_SRC_IP_LOC )) =
						*(TempPtr + Index);
	}

	/*
	 * Add Destination IP address.
	 */
	Index = IP_ADDR_LEN;
	TempPtr = (uint16_t*)DestIpAddr;
	while (Index--) {
		*(TxFramePtr + (Index + IP_REQ_DEST_IP_LOC )) =
						*(TempPtr + Index);
	}

	/*
	 * Checksum is calculated for IP field and added in the frame.
	 */
	CheckSum = CheckSumCalculation((uint16_t*)TxFrame, IP_HDR_START_LOC, IP_HDR_LEN);
	CheckSum = ~CheckSum;
	*(TxFramePtr + IP_CHECKSUM_LOC) = Xil_Htons(CheckSum);

	/*
	 * Add echo field information.
	 */
	*(TxFramePtr + ICMP_ECHO_FIELD_LOC) = Xil_Htons(XAE_ETHER_PROTO_TYPE_IP);

	/*
	 * Checksum value is initialized to zeros.
	 */
	*(TxFramePtr + ICMP_DATA_LEN) = 0x0000;

	/*
	 * Add identifier and sequence number to the frame.
	 */
	*(TxFramePtr + ICMP_IDEN_FIELD_LOC) = (IDEN_NUM);
	*(TxFramePtr + (ICMP_IDEN_FIELD_LOC + 1)) = Xil_Htons((uint16_t)(++SeqNum));

	/*
	 * Add known data to the frame.
	 */
	Index = ICMP_KNOWN_DATA_LEN;
	while (Index--) {
		*(TxFramePtr + (Index + ICMP_KNOWN_DATA_LOC)) =
				Xil_Htons(*(IcmpData + Index));
	}

	/*
	 * Checksum is calculated for Data Field and added in the frame.
	 */
	CheckSum = CheckSumCalculation((uint16_t*)TxFrame, ICMP_DATA_START_LOC,
						ICMP_DATA_FIELD_LEN );
	CheckSum = ~CheckSum;
	*(TxFramePtr + ICMP_DATA_CHECKSUM_LOC) = Xil_Htons(CheckSum);

	/*
	 * Transmit the Frame.
	 */
	printf("Sending ICMP ping request Pack: %d, Seq: %d, Pack size: %d \n",
	            NUM_OF_PING_REQ_PKTS-NumOfPingReqPkts, SeqNum, ICMP_PACKET_SIZE);
	ethSystPtr->frameSend(TxFrame, ICMP_PACKET_SIZE);
}


/*****************************************************************************/
/**
*
* This function will send a ARP request packet.
*
* @param	InstancePtr is a pointer to the instance of the EmacLite.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void PingReqstTest::SendArpReqFrame()
{
	uint16_t* TempPtr;
	uint16_t* TxFramePtr;
	int Index;

	TxFramePtr = (uint16_t*)TxFrame;

	/*
	 * Add broadcast address.
	 */
	Index = MAC_ADDR_LEN;
	while (Index--) {
		*TxFramePtr++ = BROADCAST_ADDR;
	}

	/*
	 * Add local MAC address.
	 */
	Index = 0;
	TempPtr = (uint16_t*)LocalMacAddr;
	while (Index < MAC_ADDR_LEN) {
		*TxFramePtr++ = *(TempPtr + Index);
		Index++;
	}

	/*
	 * Add
	 * 	- Ethernet proto type.
	 *	- Hardware Type
	 *	- Protocol IP Type
	 *	- IP version (IPv6/IPv4)
	 *	- ARP Request
	 */
	*TxFramePtr++ = Xil_Htons(XAE_ETHER_PROTO_TYPE_ARP);
	*TxFramePtr++ = Xil_Htons(HW_TYPE);
	*TxFramePtr++ = Xil_Htons(XAE_ETHER_PROTO_TYPE_IP);
	*TxFramePtr++ = Xil_Htons(IP_VERSION);
	*TxFramePtr++ = Xil_Htons(ARP_REQ);

	/*
	 * Add local MAC address.
	 */
	Index = 0;
	TempPtr = (uint16_t*)LocalMacAddr;
	while (Index < MAC_ADDR_LEN) {
		*TxFramePtr++ = *(TempPtr + Index);
		Index++;
	}

	/*
	 * Add local IP address.
	 */
	Index = 0;
	TempPtr = (uint16_t*)LocalIpAddr;
	while (Index < IP_ADDR_LEN) {
		*TxFramePtr++ = *(TempPtr + Index);
		Index++;
	}

	/*
	 * Fills 6 bytes of information with zeros as per protocol.
	 */
	Index = 0;
	while (Index < 3) {
		*TxFramePtr++ = 0x0000;
		Index++;
	}

	/*
	 * Add Destination IP address.
	 */
	Index = 0;
	TempPtr = (uint16_t*)DestIpAddr;
	while (Index < IP_ADDR_LEN) {
		*TxFramePtr++ = *(TempPtr + Index);
		Index++;
	}

	/*
	 * Transmit the Frame.
	 */
	printf("Sending ARP ping request Pack: %d, Seq: %d, Pack size: %d \n",
	            NUM_OF_PING_REQ_PKTS-NumOfPingReqPkts, SeqNum, ARP_REQ_PKT_SIZE);
	ethSystPtr->frameSend(TxFrame, ARP_REQ_PKT_SIZE);
}


/*****************************************************************************/
/**
*
* This function checks the match for the specified number of half words.
*
* @param	LhsPtr is a LHS entity pointer.
* @param 	RhsPtr is a RHS entity pointer.
* @param	LhsLoc is a LHS entity location.
* @param 	RhsLoc is a RHS entity location.
* @param 	Count is the number of location which has to compared.
*
* @return	XST_SUCCESS is returned when both the entities are same,
*		otherwise XST_FAILURE is returned.
*
* @note		None.
*
******************************************************************************/
int CompareData(uint16_t* LhsPtr, uint16_t* RhsPtr, int LhsLoc, int RhsLoc, int Count)
{
	int Result;
	while (Count--) {
		if (*(LhsPtr + LhsLoc + Count) == *(RhsPtr + RhsLoc + Count)) {
			Result = XST_SUCCESS;
		} else {
			Result = XST_FAILURE;
			break;
		}
	}
	return Result;
}


/*****************************************************************************/
/**
*
* This function will process the received packet. This function sends
* the echo request packet based on the ARP reply packet.
*
* @param	InstancePtr is a pointer to the instance of the EmacLite.
*
* @return	XST_SUCCESS is returned when an echo reply is received.
*		Otherwise, XST_FAILURE is returned.
*
* @note		This assumes MAC does not strip padding or CRC.
*
******************************************************************************/
int PingReqstTest::ProcessRcvFrame()
{
	uint16_t* RxFramePtr;
	uint16_t* TempPtr;
	uint16_t  CheckSum;
	int Index;
	int Match = 0;
	int DataWrong = 0;

	RxFramePtr = (uint16_t*)RxFrame;
	TempPtr    = (uint16_t*)LocalMacAddr;

	/*
	 * Check Dest Mac address of the packet with the LocalMac address.
	 */
	Match = CompareData(RxFramePtr, TempPtr, 0, 0, MAC_ADDR_LEN);
	if (Match == XST_SUCCESS) {

		/*
		 * Check ARP type.
		 */
		if (Xil_Ntohs(*(RxFramePtr + ETHER_PROTO_TYPE_LOC)) == XAE_ETHER_PROTO_TYPE_ARP ) {
			/*
			 * Check ARP status.
			 */
			if (Xil_Ntohs(*(RxFramePtr + ARP_REQ_STATUS_LOC)) == ARP_RPLY) {

				/*
				 * Check destination IP address with
				 * packet's source IP address.
				 */
				TempPtr = (uint16_t*)DestIpAddr;
				Match = CompareData(RxFramePtr,
						TempPtr, ARP_REQ_SRC_IP_LOC,
						0, IP_ADDR_LEN);
				if (Match == XST_SUCCESS) {

					/*
					 * Copy src Mac address of the received
					 * packet.
					 */
					Index = MAC_ADDR_LEN;
					TempPtr = (uint16_t*)DestMacAddr;
					while (Index--) {
						*(TempPtr + Index) =
							*(RxFramePtr +
							(SRC_MAC_ADDR_LOC +
								Index));
					}

					/*
					 * Send Echo request packet.
					 */
					SendEchoReqFrame();
				}
			}
		}

		/*
		 * Check for IP type.
		 */
		else if (Xil_Ntohs(*(RxFramePtr + ETHER_PROTO_TYPE_LOC)) == XAE_ETHER_PROTO_TYPE_IP) {
			/*
			 * Calculate checksum.
			 */
			CheckSum = CheckSumCalculation((uint16_t*)RxFramePtr, ICMP_DATA_START_LOC, ICMP_DATA_FIELD_LEN);

			/*
			 * Verify checksum, echo reply, identifier number and
			 * sequence number of the received packet.
			 */
			if ((CheckSum == CORRECT_CKSUM_VALUE) &&
			(Xil_Ntohs(*(RxFramePtr + ICMP_ECHO_FIELD_LOC)) == ECHO_REPLY) &&
			(Xil_Ntohs(*(RxFramePtr + ICMP_IDEN_FIELD_LOC)) == IDEN_NUM) &&
			(Xil_Ntohs(*(RxFramePtr + (ICMP_SEQ_NO_LOC))) == SeqNum)) {

				/*
				 * Verify data in the received packet with known
				 * data.
				 */
				TempPtr = IcmpData;
				Match = CompareData(RxFramePtr,
						TempPtr, ICMP_KNOWN_DATA_LOC,
							0, ICMP_KNOWN_DATA_LEN);
				if (Match == XST_FAILURE) {
					DataWrong = 1;
				}
			}
			if (DataWrong != 1) {
				printf("PING PASSED: Packet: %d, Seq: %d, Echo Packet received\r\n",  NUM_OF_PING_REQ_PKTS - NumOfPingReqPkts, SeqNum);
				return XST_SUCCESS;
			}
		}
	}
	return XST_FAILURE;
}


/*****************************************************************************/
/**
*
* The entry point for the EmacLite driver to ping request example in polled
* mode. This function will generate specified number of request packets as
* defined in "NUM_OF_PING_REQ_PKTS.
*
* @param	DeviceId is device ID of the XEmacLite Device.
*
* @return	XST_FAILURE to indicate failure, otherwise it will return
*		XST_SUCCESS.
*
* @note		None.
*
******************************************************************************/
int PingReqstTest::pingReqst()
{
	int Status;
	int Index;
	int Count;
	int EchoReplyStatus;
	SeqNum = 0;
	uint32_t RecvFrameLength = 0;
	NumOfPingReqPkts = NUM_OF_PING_REQ_PKTS;

    // Empty any existing receive frames.
	Status = ethSystPtr->flushReceive();
	if (Status != XST_SUCCESS) return Status;

	while (NumOfPingReqPkts--) {
	    EchoReplyStatus = XST_FAILURE;

		/*
		 * Introduce delay.
		 */
        sleep(1); // in seconds

		/*
		 * Send an ARP or an ICMP packet based on receive packet.
		 */
		if (SeqNum == 0) {
			SendArpReqFrame();
		} else {
			SendEchoReqFrame();
		}

		/*
		 * Check next 10 packets for the correct reply.
		 */
		Index = NUM_RX_PACK_CHECK_REQ;
		while (Index--) {

			/*
			 * Wait for a Receive packet.
			 */
			Count = NUM_PACK_CHECK_RX_PACK;
			while (RecvFrameLength == 0) {
				RecvFrameLength = ethSystPtr->frameRecv(RxFrame);

				/*
				 * To avoid infinite loop when no packet is
				 * received.
				 */
				if (Count-- == 0) {
					break;
				}
			}

			/*
			 * Process the Receive frame.
			 */
			if (RecvFrameLength != 0) {
				EchoReplyStatus = ProcessRcvFrame();
			}
			RecvFrameLength = 0;

			/*
			 * Comes out of loop when an echo reply packet is
			 * received.
			 */
			if (EchoReplyStatus == XST_SUCCESS) {
				break;
			}
		}

		/*
		 * If no echo reply packet is received, it reports
		 * request timed out.
		 */
		if (EchoReplyStatus == XST_FAILURE)
          printf("PING FAILED: Packet: %d, Seq: %d, Request timed out\r\n", NUM_OF_PING_REQ_PKTS - NumOfPingReqPkts, SeqNum);
	}
	return XST_SUCCESS;
}



//*********** Ping Reply Class *************
/**
* Initially started from Xilinx xemaclite_ping_reply_example.c
*
* Copyright (C) 2008 - 2020 Xilinx, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
*
* This file contains an EmacLite ping reply example in polled mode. This example
* will generate a ping reply when it receives a ping request packet from the
* external world.
*
* @note
*
* The local IP address is set to 172.16.63.121. User needs to update
* LocalIpAddr variable with a free IP address based on the network on which
* this example is to be run.
*
* The local MAC address is set to 0x000A35030201. User can update LocalMacAddr
* variable with a valid MAC address. The first three bytes contains
* the manufacture ID. 0x000A35 is XILINX manufacture ID.
*
* This program will respond continuously to a number of ping requests as defined
* by MAX_PING_REPLIES in this file.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a ktn  20/08/08 First release
* 3.00a ktn  10/22/09 Updated example to use the macros that have been changed
*		      in the driver to remove _m from the name of the macro.
* 3.01a ktn  08/06/10 Updated the example to support little endian MicroBlaze.
* 4.3   ms   01/23/17 Added xil_printf statement in main function to
*                     ensure that "Successfully ran" and "Failed" strings
*                     are available in all examples. This is a fix for
*                     CR-965028.
*
* </pre>
*
*****************************************************************************/

//*********** Ping Reply Constructor *************
PingReplyTest::PingReplyTest(EthSyst* _ethSystPtr_) {
  ethSystPtr = _ethSystPtr_;
}


/******************************************************************************/
/**
*
* This function processes the received packet and generates the corresponding
* reply packets.
*
* @note		This function assumes MAC does not strip padding or CRC.
*
******************************************************************************/
void PingReplyTest::ProcessRcvFrame()
{
	uint16_t* RxFramePtr;
	uint16_t* TxFramePtr;
	uint16_t* TempPtr;
	uint16_t  CheckSum;
	int Index;
	int PacketType = 0;

	TxFramePtr = (uint16_t*)TxFrame;
	RxFramePtr = (uint16_t*)RxFrame;

	/*
	 * Check the packet type.
	 */
	Index = MAC_ADDR_LEN;
	TempPtr = (uint16_t*)LocalMacAddr;
	while (Index--) {
		if (Xil_Ntohs((*(RxFramePtr + Index)) == BROADCAST_ADDR) &&
					(PacketType != MAC_MATCHED_PACKET)) {
			PacketType = BROADCAST_PACKET;
		} else if (Xil_Ntohs((*(RxFramePtr + Index)) == *(TempPtr + Index)) &&
					(PacketType != BROADCAST_PACKET)) {
			PacketType = MAC_MATCHED_PACKET;
		} else {
			PacketType = 0;
			break;
		}
	}

	/*
	 * Process broadcast packet.
	 */
	if (PacketType == BROADCAST_PACKET) {

		/*
		 * Check for an ARP Packet if so generate a reply.
		 */
		if (Xil_Ntohs(*(RxFramePtr + ETHER_PROTO_TYPE_LOC)) == XAE_ETHER_PROTO_TYPE_ARP) {
			/*
			 * IP address of the local machine.
			 */
			TempPtr = (uint16_t*)LocalIpAddr;

			/*
			 * Check destination IP address of the packet with
			 * local IP address.
			 */
			if (
			((*(RxFramePtr + ARP_REQ_DEST_IP_LOC_1)) == *TempPtr++) &&
			((*(RxFramePtr + ARP_REQ_DEST_IP_LOC_2)) == *TempPtr++)) {

				/*
				 * Check ARP packet type(request/reply).
				 */
				if (Xil_Ntohs(*(RxFramePtr + ARP_REQ_STATUS_LOC)) ==
								ARP_REQ) {

					/*
					 * Add destination MAC address
					 * to the reply packet (i.e) source
					 * address of the received packet.
					 */
					Index = SRC_MAC_ADDR_LOC;
					while (Index < (SRC_MAC_ADDR_LOC +
							MAC_ADDR_LEN)) {
						*TxFramePtr++ =
							*(RxFramePtr + Index);
						Index++;
					}

					/*
					 * Add source (local) MAC address
					 * to the reply packet.
					 */
					Index = 0;
					TempPtr = (uint16_t*)LocalMacAddr;
					while (Index < MAC_ADDR_LEN) {
						*TxFramePtr++ = *TempPtr++;
						Index++;
					}

					/*
					 * Add Ethernet proto type H/W
					 * type(10/3MBps),H/W address length and
					 * protocol address len (i.e)same as in
					 * the received packet
					 */
					Index = ETHER_PROTO_TYPE_LOC;
					while (Index < (ETHER_PROTO_TYPE_LOC +
							ETHER_PROTO_TYPE_LEN +
							ARP_HW_TYPE_LEN +
							ARP_HW_ADD_LEN
							+ ARP_PROTO_ADD_LEN)) {
						*TxFramePtr++ =
							*(RxFramePtr + Index);
						Index++;
					}

					/*
					 * Add ARP reply status to the reply
					 * packet.
					 */
					*TxFramePtr++ = Xil_Htons(ARP_RPLY);

					/*
					 * Add local MAC Address
					 * to the reply packet.
					 */
					TempPtr = (uint16_t*)LocalMacAddr;
					Index = 0;
					while (Index < MAC_ADDR_LEN) {
						*TxFramePtr++ = *TempPtr++;
						Index++;
					}

					/*
					 * Add local IP Address
					 * to the reply packet.
					 */
					TempPtr = (uint16_t*)LocalIpAddr;
					Index = 0;
					while (Index < IP_ADDR_LEN) {
						*TxFramePtr++ = *TempPtr++ ;
						Index++;
					}

					/*
					 * Add Destination MAC Address
					 * to the reply packet from the received
					 * packet.
					 */
					Index = SRC_MAC_ADDR_LOC;
					while (Index < (SRC_MAC_ADDR_LOC +
							MAC_ADDR_LEN)) {
						*TxFramePtr++ =
							*(RxFramePtr + Index);
						Index++;
					}

					/*
					 * Add Destination IP Address
					 * to the reply packet.
					 */
					Index = ARP_REQ_SRC_IP_LOC;
					while (Index < (ARP_REQ_SRC_IP_LOC +
							IP_ADDR_LEN)) {
						*TxFramePtr++ =
								*(RxFramePtr + Index);
						Index++;
					}

					/*
					 * Fill zeros as per protocol.
					 */
					Index = 0;
					while (Index < ARP_ZEROS_LEN) {
						*TxFramePtr++ = 0x0000;
						Index++;
					}

					/*
					 * Transmit the Reply Packet.
					 */
	                printf("Sending ARP ping reply %d with packet size %d \n", NumOfPingReplies, ARP_PACKET_SIZE);
					ethSystPtr->frameSend(TxFrame, ARP_PACKET_SIZE);
				}
			}
		}
	}

	/*
	 * Process packets whose MAC address is matched.
	 */
	if (PacketType == MAC_MATCHED_PACKET) {

		/*
		 * Check ICMP packet.
		 */
		if (Xil_Ntohs(*(RxFramePtr + ETHER_PROTO_TYPE_LOC)) == XAE_ETHER_PROTO_TYPE_IP) {
			/*
			 * Check the IP header checksum.
			 */
			CheckSum = CheckSumCalculation((uint16_t*)RxFramePtr, IP_HDR_START_LOC, IP_HDR_LEN);

			/*
			 * Check the Data field checksum.
			 */
			if (CheckSum == CORRECT_CKSUM_VALUE) {
				CheckSum = CheckSumCalculation((uint16_t*)RxFramePtr, ICMP_DATA_START_LOC, ICMP_DATA_FIELD_LEN);
				if (CheckSum == CORRECT_CKSUM_VALUE) {

					/*
					 * Add destination address
					 * to the reply packet (i.e)source
					 * address of the received packet.
					 */
					Index = SRC_MAC_ADDR_LOC;
					while (Index < (SRC_MAC_ADDR_LOC +
							MAC_ADDR_LEN)) {
						*TxFramePtr++ =
							*(RxFramePtr + Index);
						Index++;
					}

					/*
					 * Add local MAC address
					 * to the reply packet.
					 */
					Index = 0;
					TempPtr = (uint16_t*)LocalMacAddr;
					while (Index < MAC_ADDR_LEN) {
						*TxFramePtr++ = *TempPtr++;
						Index++;
					}

					/*
					 * Add protocol type
					 * header length and, packet
					 * length(60 Bytes) to the reply packet.
					 */
					Index = ETHER_PROTO_TYPE_LOC;
					while (Index < (ETHER_PROTO_TYPE_LOC +
							ETHER_PROTO_TYPE_LEN +
							IP_VERSION_LEN +
							IP_PACKET_LEN)) {
						*TxFramePtr++ =
							*(RxFramePtr + Index);
						Index++;
					}

					/*
					 * Identification field a random number
					 * which is set to IDENT_FIELD_VALUE.
					 */
					*TxFramePtr++ = IDENT_FIELD_VALUE;

					/*
					 * Add fragment type, time to live and
					 * ICM field. It is same as in the
					 * received packet.
					 */
					Index = IP_FRAG_FIELD_LOC;
					while (Index < (IP_FRAG_FIELD_LOC +
							IP_TTL_ICM_LEN +
							IP_FRAG_FIELD_LEN)) {
						*TxFramePtr++ =
							*(RxFramePtr + Index);
						Index++;
					}

					/*
					 * Checksum first set to 0 and
					 * added in this field later.
					 */
					*TxFramePtr++ = 0x0000;

					/*
					 * Add Source IP address
					 */
					Index = 0;
					TempPtr = (uint16_t*)LocalIpAddr;
					while (Index < IP_ADDR_LEN) {
						*TxFramePtr++ = *TempPtr++;
						Index++;
					}

					/*
					 * Add Destination IP address.
					 */
					Index = ICMP_REQ_SRC_IP_LOC;
					while (Index < (ICMP_REQ_SRC_IP_LOC +
							IP_ADDR_LEN)) {
						*TxFramePtr++ =
							*(RxFramePtr + Index);
						Index++;
					}

					/*
					 * Calculate checksum, and
					 * add it in the appropriate field.
					 */
					CheckSum = CheckSumCalculation((uint16_t*)TxFrame, IP_HDR_START_LOC, IP_HDR_LEN);
					CheckSum = ~CheckSum;
					*(TxFramePtr - IP_CSUM_LOC_BACK) = Xil_Htons(CheckSum);

					/*
					 * Echo reply status & checksum.
					 */
					Index = ICMP_ECHO_FIELD_LOC;
					while (Index < (ICMP_ECHO_FIELD_LOC +
							ICMP_ECHO_FIELD_LEN)) {
						*TxFramePtr++ = 0x0000;
						Index++;
					}

					/*
					 * Add data to buffer which was
					 * received from the packet.
					 */
					Index = ICMP_DATA_LOC;
					while (Index < (ICMP_DATA_LOC +
							ICMP_DATA_LEN)) {
						*TxFramePtr++ =
								(*(RxFramePtr + Index));
						Index++;
					}

					/*
					 * Generate checksum for the data and
					 * add it in the appropriate field.
					 */
					CheckSum = CheckSumCalculation((uint16_t*)TxFrame, ICMP_DATA_START_LOC, ICMP_DATA_FIELD_LEN);
					CheckSum = ~CheckSum;
					*(TxFramePtr - ICMP_DATA_CSUM_LOC_BACK)
								= Xil_Htons(CheckSum);

					/*
					 * Transmit the frame.
					 */
	                printf("Sending ICMP ping reply %d with packet size %d \n", NumOfPingReplies, ICMP_PACKET_SIZE);
					ethSystPtr->frameSend(TxFrame, ICMP_PACKET_SIZE);

					/*
					 * Increment the number of
					 * Ping replies sent.
					 */
					NumOfPingReplies++;

				}
			}
		}
	}
}


/*****************************************************************************/
/**
*
* The entry point for the EmacLite Ping reply example in polled mode.
*
* @param	DeviceId is device ID of the XEmacLite Device.
*
* @return	XST_FAILURE to indicate failure, otherwise XST_SUCCESS is
*		returned.
*
* @note		This is in a continuous loop generating a specified number of
*		ping replies as defined by MAX_PING_REPLIES.
*
******************************************************************************/
int PingReplyTest::pingReply()
{
	int Status;
	NumOfPingReplies = 0;
    uint32_t RecvFrameLength = 0; // Variable used to indicate the length of the received frame.

    // Empty any existing receive frames.
	Status = ethSystPtr->flushReceive();
	if (Status != XST_SUCCESS) return Status;

	while (true) {

		/*
		 * Wait for a Receive packet.
		 */
		while (RecvFrameLength == 0) {
			RecvFrameLength = ethSystPtr->frameRecv(RxFrame);
		}

		/*
		 * Process the Receive frame.
		 */
		ProcessRcvFrame();
		RecvFrameLength = 0;

		/*
		 * If the number of ping replies sent is equal to that
		 * specified by the user then exit out of this loop.
		 */
		if (NumOfPingReplies == MAX_PING_REPLIES) {
			return XST_SUCCESS;
		}

	}
}
