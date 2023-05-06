// ========== Copyright Header Begin ============================================
// Copyright (c) 2015 Princeton University
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

`include "define.tmp.h"
`include "mc_define.h"
`include "noc_axi4_bridge_define.vh"

module sram_top (
    input                           sys_clk,
    input                           sys_rst_n,
    output                          sram_axi_deadlock,
    input                           mc_clk,

    input   [`NOC_DATA_WIDTH-1:0]   sram_flit_in_data,
    input                           sram_flit_in_val,
    output                          sram_flit_in_rdy,

    output  [`NOC_DATA_WIDTH-1:0]   sram_flit_out_data,
    output                          sram_flit_out_val,
    input                           sram_flit_out_rdy,

    input                           uart_boot_en,

    // AXI Write Address Channel Signals
    output wire [`AXI4_ID_WIDTH     -1:0]    m_axi_awid,
    output wire [`AXI4_ADDR_WIDTH   -1:0]    m_axi_awaddr,
    output wire [`AXI4_LEN_WIDTH    -1:0]    m_axi_awlen,
    output wire [`AXI4_SIZE_WIDTH   -1:0]    m_axi_awsize,
    output wire [`AXI4_BURST_WIDTH  -1:0]    m_axi_awburst,
    output wire                                  m_axi_awlock,
    output wire [`AXI4_CACHE_WIDTH  -1:0]    m_axi_awcache,
    output wire [`AXI4_PROT_WIDTH   -1:0]    m_axi_awprot,
    output wire [`AXI4_QOS_WIDTH    -1:0]    m_axi_awqos,
    output wire [`AXI4_REGION_WIDTH -1:0]    m_axi_awregion,
    output wire [`AXI4_USER_WIDTH   -1:0]    m_axi_awuser,
    output wire                                  m_axi_awvalid,
    input  wire                                  m_axi_awready,

    // AXI Write Data Channel Signals
    output wire  [`AXI4_ID_WIDTH     -1:0]    m_axi_wid,
    output wire  [`AXI4_DATA_WIDTH   -1:0]    m_axi_wdata,
    output wire  [`AXI4_STRB_WIDTH   -1:0]    m_axi_wstrb,
    output wire                                   m_axi_wlast,
    output wire  [`AXI4_USER_WIDTH   -1:0]    m_axi_wuser,
    output wire                                   m_axi_wvalid,
    input  wire                                   m_axi_wready,

    // AXI Read Address Channel Signals
    output wire  [`AXI4_ID_WIDTH     -1:0]    m_axi_arid,
    output wire  [`AXI4_ADDR_WIDTH   -1:0]    m_axi_araddr,
    output wire  [`AXI4_LEN_WIDTH    -1:0]    m_axi_arlen,
    output wire  [`AXI4_SIZE_WIDTH   -1:0]    m_axi_arsize,
    output wire  [`AXI4_BURST_WIDTH  -1:0]    m_axi_arburst,
    output wire                                   m_axi_arlock,
    output wire  [`AXI4_CACHE_WIDTH  -1:0]    m_axi_arcache,
    output wire  [`AXI4_PROT_WIDTH   -1:0]    m_axi_arprot,
    output wire  [`AXI4_QOS_WIDTH    -1:0]    m_axi_arqos,
    output wire  [`AXI4_REGION_WIDTH -1:0]    m_axi_arregion,
    output wire  [`AXI4_USER_WIDTH   -1:0]    m_axi_aruser,
    output wire                                   m_axi_arvalid,
    input  wire                                   m_axi_arready,

    // AXI Read Data Channel Signals
    input  wire  [`AXI4_ID_WIDTH     -1:0]    m_axi_rid,
    input  wire  [`AXI4_DATA_WIDTH   -1:0]    m_axi_rdata,
    input  wire  [`AXI4_RESP_WIDTH   -1:0]    m_axi_rresp,
    input  wire                                   m_axi_rlast,
    input  wire  [`AXI4_USER_WIDTH   -1:0]    m_axi_ruser,
    input  wire                                   m_axi_rvalid,
    output wire                                   m_axi_rready,

    // AXI Write Response Channel Signals
    input  wire  [`AXI4_ID_WIDTH     -1:0]    m_axi_bid,
    input  wire  [`AXI4_RESP_WIDTH   -1:0]    m_axi_bresp,
    input  wire  [`AXI4_USER_WIDTH   -1:0]    m_axi_buser,
    input  wire                                   m_axi_bvalid,
    output wire                                   m_axi_bready,

    input wire                                    ddr_ready

  );


  // Create mc_rst_n
  reg pre_mc_rst_n;
  reg mc_rst_n;

  always @(negedge sys_rst_n or posedge mc_clk)
  begin
    if(!sys_rst_n)
    begin
      pre_mc_rst_n <= 0;
      mc_rst_n <= 0;
    end
    else
    begin
      pre_mc_rst_n <= 1;
      mc_rst_n <= pre_mc_rst_n;
    end
  end

  wire                                trans_fifo_val;
  wire    [`NOC_DATA_WIDTH-1:0]       trans_fifo_data;
  wire                                trans_fifo_rdy;

  wire                                fifo_trans_val;
  wire    [`NOC_DATA_WIDTH-1:0]       fifo_trans_data;
  wire                                fifo_trans_rdy;

  wire                               noc_axi4_bridge_rst;
  wire                               noc_axi4_bridge_init_done;
  
  assign noc_axi4_bridge_rst       = ~mc_rst_n;


  noc_bidir_afifo  sram_afifo  (
                     .clk_1           (sys_clk      ),
                     .rst_1           (~sys_rst_n   ),

                     .clk_2           (mc_clk            ),
                     .rst_2           (~mc_rst_n         ),

                     // CPU --> MIG
                     .flit_in_val_1   (sram_flit_in_val    ),
                     .flit_in_data_1  (sram_flit_in_data   ),
                     .flit_in_rdy_1   (sram_flit_in_rdy    ),

                     .flit_out_val_2  (fifo_trans_val    ),
                     .flit_out_data_2 (fifo_trans_data   ),
                     .flit_out_rdy_2  (fifo_trans_rdy    ),

                     // MIG --> CPU
                     .flit_in_val_2   (trans_fifo_val    ),
                     .flit_in_data_2  (trans_fifo_data   ),
                     .flit_in_rdy_2   (trans_fifo_rdy    ),

                     .flit_out_val_1  (sram_flit_out_val   ),
                     .flit_out_data_1 (sram_flit_out_data  ),
                     .flit_out_rdy_1  (sram_flit_out_rdy   )
                   );
                   
                    
                noc_axi4_bridge #(
                    .ADDR_OFFSET(64'h00000000),
                    .NUM_REQ_OUTSTANDING (`PITON_NUM_TILES * 4),
                    .NUM_REQ_YTHREADS (`PITON_Y_TILES),
                    .NUM_REQ_XTHREADS (`PITON_X_TILES)
                )
                 noc_axi4_bridge  (
                    .clk                (mc_clk                    ),  
                    .rst_n              (~noc_axi4_bridge_rst      ), 
                    .uart_boot_en       (uart_boot_en              ),
                    .phy_init_done      (ddr_ready ),
                    .axi_id_deadlock    (sram_axi_deadlock           ),                    

                    .src_bridge_vr_noc2_val(fifo_trans_val),
                    .src_bridge_vr_noc2_dat(fifo_trans_data),
                    .src_bridge_vr_noc2_rdy(fifo_trans_rdy),

                    .bridge_dst_vr_noc3_val(trans_fifo_val),
                    .bridge_dst_vr_noc3_dat(trans_fifo_data),
                    .bridge_dst_vr_noc3_rdy(trans_fifo_rdy),

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
                    .m_axi_bready(m_axi_bready),

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

endmodule
