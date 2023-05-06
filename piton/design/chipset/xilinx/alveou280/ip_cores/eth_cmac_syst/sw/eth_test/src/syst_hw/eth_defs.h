#ifndef ETHDEFS_H  // prevent circular inclusions
#define ETHDEFS_H  // by using protection macros

/************************** Ethernet protocol Definitions *****************************/
  enum {
    XAE_HDR_SIZE = 14,   // Size of header in bytes
    XAE_MTU      = 1500, // Max size of data in frame
    XAE_TRL_SIZE = 4,    // Size of an Ethernet trailer (FCS)
    XAE_MAX_FRAME_SIZE    = (XAE_HDR_SIZE + XAE_MTU + XAE_TRL_SIZE), // Max length of Rx frame used if length/type fieldcontains the type(> 1500)
    XAE_MAX_TX_FRAME_SIZE = (XAE_HDR_SIZE + XAE_MTU), // Max length of Tx frame

    XAE_VLAN_TAG_SIZE = 4,    // VLAN Tag Size
    XAE_HDR_VLAN_SIZE = 18,   // Size of an Ethernet header with VLAN
    XAE_MAX_VLAN_FRAME_SIZE = (XAE_MTU + XAE_HDR_VLAN_SIZE + XAE_TRL_SIZE),

    XAE_JUMBO_MTU = 8982, // Max MTU size of a jumbo Ethernet frame
    XAE_MAX_JUMBO_FRAME_SIZE = (XAE_JUMBO_MTU + XAE_HDR_SIZE + XAE_TRL_SIZE),

    XAE_HEADER_OFFSET           = 12, // Offset to length field
    XAE_HEADER_IP_LENGTH_OFFSET = 16, // IP Length Offset
    XAE_ARP_PACKET_SIZE         = 28, // Max ARP packet size

    XAE_ETHER_PROTO_TYPE_IP	  = 0x0800, // IP Protocol
    XAE_ETHER_PROTO_TYPE_ARP  = 0x0806, // ARP Protocol
    XAE_ETHER_PROTO_TYPE_VLAN =	0x8100, // VLAN Tagged

    BROADCAST_PACKET    = 1,      // Broadcast packet
    MAC_MATCHED_PACKET  = 2,      // Dest MAC matched with local MAC
    IP_ADDR_SIZE        = 4,      // IP Address size in Bytes
    HW_TYPE             = 0x01,   // Hardware type (10/100 Mbps)
    IP_VERSION          = 0x0604, // IP version ipv4/ipv6
    ARP_REQ             = 0x0001, // ARP Request bits in Rx packet
    ARP_RPLY            = 0x0002, // ARP status bits indicating reply
    ARP_REQ_PKT_SIZE    = 0x2A,   // ARP request packet size
    ARP_PACKET_SIZE     = 0x3C,   // ARP packet len 60 Bytes
    ECHO_REPLY          = 0x00,   // Echo reply
    ICMP_PACKET_SIZE    = 0x4A,   // ICMP packet length 74 Bytes including Src and Dest MAC Address
    BROADCAST_ADDR      = 0xFFFF, // Broadcast Address
    CORRECT_CKSUM_VALUE = 0xFFFF, // Correct checksum value
    IDENT_FIELD_VALUE   = 0x9263, // Identification field (random num)
    IDEN_NUM            = 0x02,   // ICMP identifier number

    //--- Definitions for the locations and length of some of the fields in a IP packet. The lengths are defined in Half-Words (2 bytes).
    SRC_MAC_ADDR_LOC     = 3, // Source MAC address location
    MAC_ADDR_LEN         = 3, // MAC address length
    ETHER_PROTO_TYPE_LOC = 6, // Ethernet Proto type location
    ETHER_PROTO_TYPE_LEN = 1, // Ethernet protocol Type length

    ARP_HW_TYPE_LEN       = 1,  // Hardware Type length
    ARP_PROTO_TYPE_LEN    = 1,  // Protocol Type length
    ARP_HW_ADD_LEN        = 1,  // Hardware address length
    ARP_PROTO_ADD_LEN     = 1,  // Protocol address length
    ARP_ZEROS_LEN         = 9,  // Length to be filled with zeros
    ARP_REQ_STATUS_LOC    = 10, // ARP request location
    ARP_REQ_SRC_IP_LOC    = 14, // Src IP address location of ARP request
    ARP_REQ_DEST_IP_LOC_1 = 19, // Destination IP's 1st half word location
    ARP_REQ_DEST_IP_LOC_2 = 20, // Destination IP's 2nd half word location

    IP_VERSION_LEN     = 1,  // IP Version length
    IP_PACKET_LEN      = 1,  // IP Packet length field
    IP_TTL_ICM_LEN     = 1,  // Time to live and ICM fields length
    IP_HDR_START_LOC   = 7,  // IP header start location
    IP_HEADER_INFO_LEN = 7,  // IP header information length
    IP_HDR_LEN         = 10, // IP Header length
    IP_FRAG_FIELD_LOC  = 10, // Fragment field location
    IP_FRAG_FIELD_LEN  = 1,  // Fragment field len in ICMP packet
    IP_CHECKSUM_LOC    = 12, // IP header checksum location
    IP_CSUM_LOC_BACK   = 5,  // IP checksum location from end of frame
    IP_REQ_SRC_IP_LOC  = 13, // Src IP add loc of ICMP req
    IP_REQ_DEST_IP_LOC = 15, // Dest IP add loc of ICMP req
    IP_ADDR_LEN        = 2,  // Size of IP address in half-words

    ICMP_TYPE_LEN           = 1,  // ICMP Type length
    ICMP_REQ_SRC_IP_LOC     = 13, // Src IP address location of ICMP request
    ICMP_ECHO_FIELD_LOC     = 17, // Echo field location
    ICMP_ECHO_FIELD_LEN     = 2,  // Echo field length in half-words
    ICMP_DATA_START_LOC     = 17, // Data field start location
    ICMP_DATA_FIELD_LEN     = 20, // Data field length
    ICMP_DATA_LEN           = 18, // ICMP data length
    ICMP_DATA_LOC           = 19, // ICMP data location including identifier number and sequence number
    ICMP_DATA_CHECKSUM_LOC	= 18, // ICMP data checksum location
    ICMP_DATA_CSUM_LOC_BACK = 19, // Data checksum location from end of frame
    ICMP_IDEN_FIELD_LOC     = 19, // Identifier field loc
    ICMP_SEQ_NO_LOC         = 20, // sequence number location
    ICMP_KNOWN_DATA_LOC     = 21, // ICMP known data start loc
    ICMP_KNOWN_DATA_LEN     = 16  // ICMP known data length
  };

#endif // end of protection macro
