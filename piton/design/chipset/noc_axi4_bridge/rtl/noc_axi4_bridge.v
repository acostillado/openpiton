// Modified by Barcelona Supercomputing Center on March 3rd, 2022
// ========== Copyright Header Begin ============================================
// Copyright (c) 2019 Princeton University
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of Princeton University nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY PRINCETON UNIVERSITY "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL PRINCETON UNIVERSITY BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ========== Copyright Header End ============================================

`include "mc_define.h"
`include "define.tmp.h"
`include "noc_axi4_bridge_define.vh"

module noc_axi4_bridge #(
    parameter AXI4_DAT_WIDTH_USED = `AXI4_DATA_WIDTH, // actually used AXI Data width (down converted if needed)
    parameter SWAP_ENDIANESS = 0, // swap endianess, needed when used in conjunction with a little endian core like Ariane
    parameter NOC2AXI_DESER_ORDER = 0, // NOC words to AXI word deserialization order
    parameter ADDR_OFFSET = 64'h0,
    parameter RDWR_INORDER = 0, // control of Rd/Wr responses order
    parameter NUM_REQ_OUTSTANDING = 4,
    parameter NUM_REQ_MSHRID_LBIT = 0,
    parameter NUM_REQ_MSHRID_BITS = 0,
    parameter NUM_REQ_YTHREADS = 1,
    parameter NUM_REQ_XTHREADS = 1
) (
    // Clock + Reset
    input  wire                                   clk,
    input  wire                                   rst_n,
    input  wire                                   uart_boot_en,
    input  wire                                   phy_init_done, 
    output                                        axi_id_deadlock,

    // Noc interface
    input  wire                                   src_bridge_vr_noc2_val,
    input  wire [`NOC_DATA_WIDTH-1:0]             src_bridge_vr_noc2_dat,
    output wire                                   src_bridge_vr_noc2_rdy,
    output wire                                   bridge_dst_vr_noc3_val,
    output wire [`NOC_DATA_WIDTH-1:0]             bridge_dst_vr_noc3_dat,
    input  wire                                   bridge_dst_vr_noc3_rdy,

    // AXI interface
    output wire [`AXI4_ID_WIDTH     -1:0]    m_axi_awid,
    output wire [`AXI4_ADDR_WIDTH   -1:0]    m_axi_awaddr,
    output wire [`AXI4_LEN_WIDTH    -1:0]    m_axi_awlen,
    output wire [`AXI4_SIZE_WIDTH   -1:0]    m_axi_awsize,
    output wire [`AXI4_BURST_WIDTH  -1:0]    m_axi_awburst,
    output wire                              m_axi_awlock,
    output wire [`AXI4_CACHE_WIDTH  -1:0]    m_axi_awcache,
    output wire [`AXI4_PROT_WIDTH   -1:0]    m_axi_awprot,
    output wire [`AXI4_QOS_WIDTH    -1:0]    m_axi_awqos,
    output wire [`AXI4_REGION_WIDTH -1:0]    m_axi_awregion,
    output wire [`AXI4_USER_WIDTH   -1:0]    m_axi_awuser,
    output wire                              m_axi_awvalid,
    input  wire                              m_axi_awready,

    output wire  [`AXI4_ID_WIDTH     -1:0]    m_axi_wid,
    output wire  [`AXI4_DATA_WIDTH   -1:0]    m_axi_wdata,
    output wire  [`AXI4_STRB_WIDTH   -1:0]    m_axi_wstrb,
    output wire                               m_axi_wlast,
    output wire  [`AXI4_USER_WIDTH   -1:0]    m_axi_wuser,
    output wire                               m_axi_wvalid,
    input  wire                               m_axi_wready,

    output wire  [`AXI4_ID_WIDTH     -1:0]    m_axi_arid,
    output wire  [`AXI4_ADDR_WIDTH   -1:0]    m_axi_araddr,
    output wire  [`AXI4_LEN_WIDTH    -1:0]    m_axi_arlen,
    output wire  [`AXI4_SIZE_WIDTH   -1:0]    m_axi_arsize,
    output wire  [`AXI4_BURST_WIDTH  -1:0]    m_axi_arburst,
    output wire                               m_axi_arlock,
    output wire  [`AXI4_CACHE_WIDTH  -1:0]    m_axi_arcache,
    output wire  [`AXI4_PROT_WIDTH   -1:0]    m_axi_arprot,
    output wire  [`AXI4_QOS_WIDTH    -1:0]    m_axi_arqos,
    output wire  [`AXI4_REGION_WIDTH -1:0]    m_axi_arregion,
    output wire  [`AXI4_USER_WIDTH   -1:0]    m_axi_aruser,
    output wire                               m_axi_arvalid,
    input  wire                               m_axi_arready,

    input  wire  [`AXI4_ID_WIDTH     -1:0]    m_axi_rid,
    input  wire  [`AXI4_DATA_WIDTH   -1:0]    m_axi_rdata,
    input  wire  [`AXI4_RESP_WIDTH   -1:0]    m_axi_rresp,
    input  wire                               m_axi_rlast,
    input  wire  [`AXI4_USER_WIDTH   -1:0]    m_axi_ruser,
    input  wire                               m_axi_rvalid,
    output wire                               m_axi_rready,

    input  wire  [`AXI4_ID_WIDTH     -1:0]    m_axi_bid,
    input  wire  [`AXI4_RESP_WIDTH   -1:0]    m_axi_bresp,
    input  wire  [`AXI4_USER_WIDTH   -1:0]    m_axi_buser,
    input  wire                               m_axi_bvalid,
    output wire                               m_axi_bready
);

wire [`MSG_HEADER_WIDTH-1:0] deser_header;
wire [`AXI4_DATA_WIDTH-1:0] deser_data;
wire deser_val;
wire deser_rdy;

wire [`AXI4_ADDR_WIDTH -1:0] read_req_addr;
wire [`AXI4_ID_WIDTH   -1:0] read_req_id;
wire read_req_val;
wire read_req_rdy;
wire [`AXI4_DATA_WIDTH-1:0] read_resp_data;
wire [`AXI4_ID_WIDTH  -1:0] read_resp_id;
wire read_resp_val;
wire read_resp_rdy;

wire write_req_val;
wire [`AXI4_ADDR_WIDTH -1:0] write_req_addr;
wire [`AXI4_ID_WIDTH   -1:0] write_req_id;
wire [`AXI4_DATA_WIDTH -1:0] write_req_data;
wire [`AXI4_STRB_WIDTH -1:0] write_req_strb;
wire write_req_rdy;
wire [`AXI4_ID_WIDTH   -1:0] write_resp_id;
wire write_resp_val;
wire write_resp_rdy;

wire [`MSG_HEADER_WIDTH-1:0] ser_header;
wire [`AXI4_DATA_WIDTH-1:0] ser_data;
wire ser_val;
wire ser_rdy;


noc_axi4_bridge_buffer #(
    .SWAP_ENDIANESS (SWAP_ENDIANESS),
    .ADDR_OFFSET (ADDR_OFFSET),
    .RDWR_INORDER (RDWR_INORDER),
    .NUM_REQ_OUTSTANDING (NUM_REQ_OUTSTANDING),
    .NUM_REQ_MSHRID_LBIT (NUM_REQ_MSHRID_LBIT),
    .NUM_REQ_MSHRID_BITS (NUM_REQ_MSHRID_BITS),
    .NUM_REQ_YTHREADS (NUM_REQ_YTHREADS),
    .NUM_REQ_XTHREADS (NUM_REQ_XTHREADS)
) noc_axi4_bridge_buffer (
    .clk(clk),
    .rst_n(rst_n),
    .uart_boot_en(uart_boot_en),
    .axi_id_deadlock(axi_id_deadlock),

    .deser_header(deser_header),
    .deser_data(deser_data),
    .deser_val(deser_val),
    .deser_rdy(deser_rdy),

    .read_req_addr(read_req_addr),
    .read_req_id(read_req_id),
    .read_req_val(read_req_val),
    .read_req_rdy(read_req_rdy),

    .read_resp_data(read_resp_data),
    .read_resp_id(read_resp_id),
    .read_resp_val(read_resp_val),
    .read_resp_rdy(read_resp_rdy),

    .write_req_addr(write_req_addr),
    .write_req_id(write_req_id),
    .write_req_data(write_req_data),
    .write_req_strb(write_req_strb),
    .write_req_val(write_req_val), 
    .write_req_rdy(write_req_rdy),

    .write_resp_id(write_resp_id), 
    .write_resp_val(write_resp_val), 
    .write_resp_rdy(write_resp_rdy), 

    .ser_header(ser_header), 
    .ser_data(ser_data), 
    .ser_val(ser_val), 
    .ser_rdy(ser_rdy)
);

noc_axi4_bridge_deser #(
    .NOC2AXI_DESER_ORDER (NOC2AXI_DESER_ORDER)
) noc_axi4_bridge_deser (
    .clk(clk), 
    .rst_n(rst_n), 

    .flit_in(src_bridge_vr_noc2_dat), 
    .flit_in_val(src_bridge_vr_noc2_val), 
    .flit_in_rdy(src_bridge_vr_noc2_rdy), 
    .phy_init_done(phy_init_done),

    .header_out(deser_header), 
    .data_out(deser_data), 
    .out_val(deser_val), 
    .out_rdy(deser_rdy)
);

noc_axi4_bridge_read #(
    .AXI4_DAT_WIDTH_USED (AXI4_DAT_WIDTH_USED)
) noc_axi4_bridge_read (
    .clk(clk), 
    .rst_n(rst_n), 

    // NOC interface
    .req_val(read_req_val),
    .req_addr(read_req_addr),
    .req_id(read_req_id),
    .req_rdy(read_req_rdy),

    .resp_val(read_resp_val),
    .resp_id(read_resp_id),
    .resp_data(read_resp_data),
    .resp_rdy(read_resp_rdy),

    // axi read interface
    .m_axi_arid(m_axi_arid),
    .m_axi_araddr(m_axi_araddr),
    .m_axi_arlen(m_axi_arlen),
    .m_axi_arsize(m_axi_arsize),
    .m_axi_arburst(m_axi_arburst),
    .m_axi_arlock(m_axi_arlock),
    .m_axi_arcache(m_axi_arcache),
    .m_axi_arprot(m_axi_arprot), 
    .m_axi_arqos(m_axi_arqos),
    .m_axi_arregion(m_axi_arregion),
    .m_axi_aruser(m_axi_aruser),
    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),

    .m_axi_rid(m_axi_rid),
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp),
    .m_axi_rlast(m_axi_rlast), 
    .m_axi_ruser(m_axi_ruser),
    .m_axi_rvalid(m_axi_rvalid),
    .m_axi_rready(m_axi_rready)
);

noc_axi4_bridge_write #(
    .AXI4_DAT_WIDTH_USED (AXI4_DAT_WIDTH_USED)
) noc_axi4_bridge_write (
    // Clock + Reset
    .clk(clk),
    .rst_n(rst_n),

    // NOC interface
    .req_val(write_req_val),
    .req_addr(write_req_addr),
    .req_id(write_req_id),
    .req_data(write_req_data),
    .req_strb(write_req_strb),
    .req_rdy(write_req_rdy),

    .resp_val(write_resp_val),
    .resp_id(write_resp_id),
    .resp_rdy(write_resp_rdy),

    // AXI write interface
    .m_axi_awid(m_axi_awid),
    .m_axi_awaddr(m_axi_awaddr),
    .m_axi_awlen(m_axi_awlen),
    .m_axi_awsize(m_axi_awsize),
    .m_axi_awburst(m_axi_awburst),
    .m_axi_awlock(m_axi_awlock),
    .m_axi_awcache(m_axi_awcache),
    .m_axi_awprot(m_axi_awprot),
    .m_axi_awqos(m_axi_awqos),
    .m_axi_awregion(m_axi_awregion),
    .m_axi_awuser(m_axi_awuser),
    .m_axi_awvalid(m_axi_awvalid),
    .m_axi_awready(m_axi_awready),

    .m_axi_wid(m_axi_wid),
    .m_axi_wdata(m_axi_wdata),
    .m_axi_wstrb(m_axi_wstrb),
    .m_axi_wlast(m_axi_wlast),
    .m_axi_wuser(m_axi_wuser),
    .m_axi_wvalid(m_axi_wvalid),
    .m_axi_wready(m_axi_wready),

    .m_axi_bid(m_axi_bid),
    .m_axi_bresp(m_axi_bresp),
    .m_axi_buser(m_axi_buser),
    .m_axi_bvalid(m_axi_bvalid),
    .m_axi_bready(m_axi_bready)
);

noc_axi4_bridge_ser noc_axi4_bridge_ser(
    .clk(clk), 
    .rst_n(rst_n), 

    .header_in(ser_header), 
    .data_in(ser_data), 
    .in_val(ser_val), 
    .in_rdy(ser_rdy), 

    .flit_out(bridge_dst_vr_noc3_dat), 
    .flit_out_val(bridge_dst_vr_noc3_val), 
    .flit_out_rdy(bridge_dst_vr_noc3_rdy)
);

endmodule
