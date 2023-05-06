`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/03/2021 07:19:01 PM
// Design Name:
// Module Name: system_top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module system_top(
    input sysclk0_clk_n,
    input sysclk0_clk_p,
    input  [15:0] pci_express_x16_rxn,
    input  [15:0] pci_express_x16_rxp,
    output [15:0] pci_express_x16_txn,
    output [15:0] pci_express_x16_txp,
    input  pcie_perstn,
    input  pcie_refclk_n,
    input  pcie_refclk_p,
    output hbm_cattrip,
    output  uart_tx,
    input   uart_rx

  );
  
wire sys_clk;
wire mc_clk;

wire init_calib_complete;

  // AXI Write Address Channel Signals
wire [5:0]    mem_axi_awid;
wire [63:0]   mem_axi_awaddr;
wire [7:0]    mem_axi_awlen;
wire [2:0]    mem_axi_awsize;
wire [1:0]    mem_axi_awburst;
wire          mem_axi_awlock;
wire [3:0]    mem_axi_awcache;
wire [2:0]    mem_axi_awprot;
wire [3:0]    mem_axi_awqos;
wire [3:0]    mem_axi_awregion;
wire [10:0]   mem_axi_awuser;
wire          mem_axi_awvalid;
wire          mem_axi_awready;

// AXI Write Data Channel Signals
wire  [5:0]   mem_axi_wid;
wire  [511:0] mem_axi_wdata;
wire  [63:0]  mem_axi_wstrb;
wire          mem_axi_wlast;
wire  [10:0]  mem_axi_wuser;
wire          mem_axi_wvalid;
wire          mem_axi_wready;

// AXI Read Address Channel Signals
wire  [5:0]   mem_axi_arid;
wire  [63:0]  mem_axi_araddr;
wire  [7:0]   mem_axi_arlen;
wire  [2:0]   mem_axi_arsize;
wire  [1:0]   mem_axi_arburst;
wire          mem_axi_arlock;
wire  [3:0]   mem_axi_arcache;
wire  [2:0]   mem_axi_arprot;
wire  [3:0]   mem_axi_arqos;
wire  [3:0]   mem_axi_arregion;
wire  [10:0]  mem_axi_aruser;
wire          mem_axi_arvalid;
wire          mem_axi_arready;

// AXI Read Data Channel Signals
wire  [5:0]   mem_axi_rid;
wire  [511:0] mem_axi_rdata;
wire  [1:0]   mem_axi_rresp;
wire          mem_axi_rlast;
wire  [10:0]  mem_axi_ruser;
wire          mem_axi_rvalid;
wire          mem_axi_rready;

// AXI Write Response Channel Signals
wire  [5:0]   mem_axi_bid;
wire  [1:0]   mem_axi_bresp;
wire  [10:0]  mem_axi_buser;
wire          mem_axi_bvalid;
wire          mem_axi_bready;
  
wire [`AXI4_ID_WIDTH     -1:0]     eth_axi_awid;
wire [`AXI4_ADDR_WIDTH   -1:0]     eth_axi_awaddr;
wire [`AXI4_LEN_WIDTH    -1:0]     eth_axi_awlen;
wire [`AXI4_SIZE_WIDTH   -1:0]     eth_axi_awsize;
wire [`AXI4_BURST_WIDTH  -1:0]     eth_axi_awburst;
wire                               eth_axi_awlock;
wire [`AXI4_CACHE_WIDTH  -1:0]     eth_axi_awcache;
wire [`AXI4_PROT_WIDTH   -1:0]     eth_axi_awprot;
wire [`AXI4_QOS_WIDTH    -1:0]     eth_axi_awqos;
wire [`AXI4_REGION_WIDTH -1:0]     eth_axi_awregion;
wire [`AXI4_USER_WIDTH   -1:0]     eth_axi_awuser;
wire                               eth_axi_awvalid;
wire                               eth_axi_awready;

wire  [`AXI4_ID_WIDTH     -1:0]    eth_axi_wid;
wire  [`AXI4_DATA_WIDTH   -1:0]    eth_axi_wdata;
wire  [`AXI4_STRB_WIDTH   -1:0]    eth_axi_wstrb;
wire                               eth_axi_wlast;
wire  [`AXI4_USER_WIDTH   -1:0]    eth_axi_wuser;
wire                               eth_axi_wvalid;
wire                               eth_axi_wready;

wire  [`AXI4_ID_WIDTH     -1:0]    eth_axi_arid;
wire  [`AXI4_ADDR_WIDTH   -1:0]    eth_axi_araddr;
wire  [`AXI4_LEN_WIDTH    -1:0]    eth_axi_arlen;
wire  [`AXI4_SIZE_WIDTH   -1:0]    eth_axi_arsize;
wire  [`AXI4_BURST_WIDTH  -1:0]    eth_axi_arburst;
wire                               eth_axi_arlock;
wire  [`AXI4_CACHE_WIDTH  -1:0]    eth_axi_arcache;
wire  [`AXI4_PROT_WIDTH   -1:0]    eth_axi_arprot;
wire  [`AXI4_QOS_WIDTH    -1:0]    eth_axi_arqos;
wire  [`AXI4_REGION_WIDTH -1:0]    eth_axi_arregion;
wire  [`AXI4_USER_WIDTH   -1:0]    eth_axi_aruser;
wire                               eth_axi_arvalid;
wire                               eth_axi_arready;

wire  [`AXI4_ID_WIDTH     -1:0]    eth_axi_rid;
wire  [`AXI4_DATA_WIDTH   -1:0]    eth_axi_rdata;
wire  [`AXI4_RESP_WIDTH   -1:0]    eth_axi_rresp;
wire                               eth_axi_rlast;
wire  [`AXI4_USER_WIDTH   -1:0]    eth_axi_ruser;
wire                               eth_axi_rvalid;
wire                               eth_axi_rready;

wire  [`AXI4_ID_WIDTH     -1:0]    eth_axi_bid;
wire  [`AXI4_RESP_WIDTH   -1:0]    eth_axi_bresp;
wire  [`AXI4_USER_WIDTH   -1:0]    eth_axi_buser;
wire                               eth_axi_bvalid;
wire                               eth_axi_bready;



  wire [`AXI4_ID_WIDTH     -1:0]     sram_axi_awid;
  wire [`AXI4_ADDR_WIDTH   -1:0]     sram_axi_awaddr;
  wire [`AXI4_LEN_WIDTH    -1:0]     sram_axi_awlen;
  wire [`AXI4_SIZE_WIDTH   -1:0]     sram_axi_awsize;
  wire [`AXI4_BURST_WIDTH  -1:0]     sram_axi_awburst;
  wire                               sram_axi_awlock;
  wire [`AXI4_CACHE_WIDTH  -1:0]     sram_axi_awcache;
  wire [`AXI4_PROT_WIDTH   -1:0]     sram_axi_awprot;
  wire [`AXI4_QOS_WIDTH    -1:0]     sram_axi_awqos;
  wire [`AXI4_REGION_WIDTH -1:0]     sram_axi_awregion;
  wire [`AXI4_USER_WIDTH   -1:0]     sram_axi_awuser;
  wire                               sram_axi_awvalid;
  wire                               sram_axi_awready;

  wire  [`AXI4_ID_WIDTH     -1:0]    sram_axi_wid;
  wire  [`AXI4_DATA_WIDTH   -1:0]    sram_axi_wdata;
  wire  [`AXI4_STRB_WIDTH   -1:0]    sram_axi_wstrb;
  wire                               sram_axi_wlast;
  wire  [`AXI4_USER_WIDTH   -1:0]    sram_axi_wuser;
  wire                               sram_axi_wvalid;
  wire                               sram_axi_wready;

  wire  [`AXI4_ID_WIDTH     -1:0]    sram_axi_arid;
  wire  [`AXI4_ADDR_WIDTH   -1:0]    sram_axi_araddr;
  wire  [`AXI4_LEN_WIDTH    -1:0]    sram_axi_arlen;
  wire  [`AXI4_SIZE_WIDTH   -1:0]    sram_axi_arsize;
  wire  [`AXI4_BURST_WIDTH  -1:0]    sram_axi_arburst;
  wire                               sram_axi_arlock;
  wire  [`AXI4_CACHE_WIDTH  -1:0]    sram_axi_arcache;
  wire  [`AXI4_PROT_WIDTH   -1:0]    sram_axi_arprot;
  wire  [`AXI4_QOS_WIDTH    -1:0]    sram_axi_arqos;
  wire  [`AXI4_REGION_WIDTH -1:0]    sram_axi_arregion;
  wire  [`AXI4_USER_WIDTH   -1:0]    sram_axi_aruser;
  wire                               sram_axi_arvalid;
  wire                               sram_axi_arready;

  wire  [`AXI4_ID_WIDTH     -1:0]    sram_axi_rid;
  wire  [`AXI4_DATA_WIDTH   -1:0]    sram_axi_rdata;
  wire  [`AXI4_RESP_WIDTH   -1:0]    sram_axi_rresp;
  wire                               sram_axi_rlast;
  wire  [`AXI4_USER_WIDTH   -1:0]    sram_axi_ruser;
  wire                               sram_axi_rvalid;
  wire                               sram_axi_rready;

  wire  [`AXI4_ID_WIDTH     -1:0]    sram_axi_bid;
  wire  [`AXI4_RESP_WIDTH   -1:0]    sram_axi_bresp;
  wire  [`AXI4_USER_WIDTH   -1:0]    sram_axi_buser;
  wire                               sram_axi_bvalid;
  wire                               sram_axi_bready;



  meep_shell meep_shell  
             (.axi4_mm_araddr(mem_axi_araddr),
              .axi4_mm_arburst(mem_axi_arburst),
              .axi4_mm_arcache(mem_axi_arcache),
              .axi4_mm_arid(mem_axi_arid),
              .axi4_mm_arlen(mem_axi_arlen),
              .axi4_mm_arlock(mem_axi_arlock),
              .axi4_mm_arprot(mem_axi_arprot),
              .axi4_mm_arqos(mem_axi_arqos),
              .axi4_mm_arready(mem_axi_arready),
              .axi4_mm_arsize(mem_axi_arsize),
              //.axi4_mm_aruser(mem_axi_aruser),
              .axi4_mm_arvalid(mem_axi_arvalid),

              .axi4_mm_awaddr(mem_axi_awaddr),
              .axi4_mm_awburst(mem_axi_awburst),
              .axi4_mm_awcache(mem_axi_awcache),
              .axi4_mm_awid(mem_axi_awid),
              .axi4_mm_awlen(mem_axi_awlen),
              .axi4_mm_awlock(mem_axi_awlock),
              .axi4_mm_awprot(mem_axi_awprot),
              .axi4_mm_awqos(mem_axi_awqos),
              .axi4_mm_awready(mem_axi_awready),
              .axi4_mm_awsize(mem_axi_awsize),
              //.axi4_mm_awuser(mem_axi_awuser),
              .axi4_mm_awvalid(mem_axi_awvalid),

              .axi4_mm_bid(mem_axi_bid),
              .axi4_mm_bready(mem_axi_bready),
              .axi4_mm_bresp(mem_axi_bresp),
              //.axi4_mm_buser(mem_axi_buser),
              .axi4_mm_bvalid(mem_axi_bvalid),

              .axi4_mm_rdata(mem_axi_rdata),
              .axi4_mm_rid(mem_axi_rid),
              .axi4_mm_rlast(mem_axi_rlast),
              .axi4_mm_rready(mem_axi_rready),
              .axi4_mm_rresp(mem_axi_rresp),
              //.axi4_mm_ruser(mem_axi_ruser),
              .axi4_mm_rvalid(mem_axi_rvalid),

              .axi4_mm_wdata(mem_axi_wdata),
              .axi4_mm_wlast(mem_axi_wlast),
              .axi4_mm_wready(mem_axi_wready),
              .axi4_mm_wstrb(mem_axi_wstrb),
              //.axi4_mm_wuser(mem_axi_wuser),
              .axi4_mm_wvalid(mem_axi_wvalid),

              // Ethernet

              .eth_axi_araddr(eth_axi_araddr),
              .eth_axi_arburst(eth_axi_arburst),
              .eth_axi_arcache(eth_axi_arcache),
              .eth_axi_arid(eth_axi_arid),
              .eth_axi_arlen(eth_axi_arlen),
              .eth_axi_arlock(eth_axi_arlock),
              .eth_axi_arprot(eth_axi_arprot),
              // .eth_axi_arqos(eth_axi_arqos),
              .eth_axi_arready(eth_axi_arready),
              .eth_axi_arsize(eth_axi_arsize),
              // .eth_axi_aruser(eth_axi_aruser),
              .eth_axi_arvalid(eth_axi_arvalid),
              
              .eth_axi_awaddr(eth_axi_awaddr),
              .eth_axi_awburst(eth_axi_awburst),
              .eth_axi_awcache(eth_axi_awcache),
              .eth_axi_awid(eth_axi_awid),
              .eth_axi_awlen(eth_axi_awlen),
              .eth_axi_awlock(eth_axi_awlock),
              .eth_axi_awprot(eth_axi_awprot),
              // .eth_axi_awqos(eth_axi_awqos),
              .eth_axi_awready(eth_axi_awready),
              .eth_axi_awsize(eth_axi_awsize),
              // .eth_axi_awuser(eth_axi_awuser),
              .eth_axi_awvalid(eth_axi_awvalid),
              
              .eth_axi_bid(eth_axi_bid),
              .eth_axi_bready(eth_axi_bready),
              .eth_axi_bresp(eth_axi_bresp),
              // .eth_axi_buser(eth_axi_buser),
              .eth_axi_bvalid(eth_axi_bvalid),
              
              .eth_axi_rdata(eth_axi_rdata),
              .eth_axi_rid(eth_axi_rid),
              .eth_axi_rlast(eth_axi_rlast),
              .eth_axi_rready(eth_axi_rready),
              .eth_axi_rresp(eth_axi_rresp),
              // .eth_axi_ruser(eth_axi_ruser),
              .eth_axi_rvalid(eth_axi_rvalid),
              
              .eth_axi_wdata(eth_axi_wdata),
              .eth_axi_wlast(eth_axi_wlast),
              .eth_axi_wready(eth_axi_wready),
              .eth_axi_wstrb(eth_axi_wstrb),
              // .eth_axi_wuser(eth_axi_wuser),
              .eth_axi_wvalid(eth_axi_wvalid),

              .axi4_sram_araddr(sram_axi_araddr),
              .axi4_sram_arburst(sram_axi_arburst),
              .axi4_sram_arcache(sram_axi_arcache),
              .axi4_sram_arid(sram_axi_arid),
              .axi4_sram_arlen(sram_axi_arlen),
              .axi4_sram_arlock(sram_axi_arlock),
              .axi4_sram_arprot(sram_axi_arprot),
              // .axi4_sram_arqos(sram_axi_arqos),
              .axi4_sram_arready(sram_axi_arready),
              .axi4_sram_arsize(sram_axi_arsize),
              // .axi4_sram_aruser(sram_axi_aruser),
              .axi4_sram_arvalid(sram_axi_arvalid),

              .axi4_sram_awaddr(sram_axi_awaddr),
              .axi4_sram_awburst(sram_axi_awburst),
              .axi4_sram_awcache(sram_axi_awcache),
              .axi4_sram_awid(sram_axi_awid),
              .axi4_sram_awlen(sram_axi_awlen),
              .axi4_sram_awlock(sram_axi_awlock),
              .axi4_sram_awprot(sram_axi_awprot),
              // .axi4_sram_awqos(sram_axi_awqos),
              .axi4_sram_awready(sram_axi_awready),
              .axi4_sram_awsize(sram_axi_awsize),
              // .axi4_sram_awuser(sram_axi_awuser),
              .axi4_sram_awvalid(sram_axi_awvalid),

              .axi4_sram_bid(sram_axi_bid),
              .axi4_sram_bready(sram_axi_bready),
              .axi4_sram_bresp(sram_axi_bresp),
              // .axi4_sram_buser(sram_axi_buser),
              .axi4_sram_bvalid(sram_axi_bvalid),

              .axi4_sram_rdata(sram_axi_rdata),
              .axi4_sram_rid(sram_axi_rid),
              .axi4_sram_rlast(sram_axi_rlast),
              .axi4_sram_rready(sram_axi_rready),
              .axi4_sram_rresp(sram_axi_rresp),
              // .axi4_sram_ruser(sram_axi_ruser),
              .axi4_sram_rvalid(sram_axi_rvalid),

              .axi4_sram_wdata(sram_axi_wdata),
              .axi4_sram_wlast(sram_axi_wlast),
              .axi4_sram_wready(sram_axi_wready),
              .axi4_sram_wstrb(sram_axi_wstrb),
              // .axi4_sram_wuser(sram_axi_wuser),
              .axi4_sram_wvalid(sram_axi_wvalid),


              .mem_calib_complete(init_calib_complete),


              .hbm_cattrip(hbm_cattrip),

              .sys_clk(sys_clk),
              .mc_clk(mc_clk),
              
              .sysclk0_clk_n(sysclk0_clk_n),
              .sysclk0_clk_p(sysclk0_clk_p),

              .pci_express_x16_rxn(pci_express_x16_rxn),
              .pci_express_x16_rxp(pci_express_x16_rxp),
              .pci_express_x16_txn(pci_express_x16_txn),
              .pci_express_x16_txp(pci_express_x16_txp),
              .pcie_gpio(pcie_gpio),
              .pcie_perstn(pcie_perstn),
              .pcie_refclk_clk_n( pcie_refclk_n),
              .pcie_refclk_clk_p( pcie_refclk_p)
             );


  openpiton_wrapper openpiton(
                      .sys_clk(sys_clk)	,
                      .pcie_gpio(pcie_gpio) ,
                      .mc_clk(mc_clk),
                      // AXI Write Address Channel Signals
                      .mem_axi_awid(mem_axi_awid),
                      .mem_axi_awaddr(mem_axi_awaddr),
                      .mem_axi_awlen(mem_axi_awlen),
                      .mem_axi_awsize(mem_axi_awsize),
                      .mem_axi_awburst(mem_axi_awburst),
                      .mem_axi_awlock(mem_axi_awlock),
                      .mem_axi_awcache(mem_axi_awcache),
                      .mem_axi_awprot(mem_axi_awprot),
                      .mem_axi_awqos(mem_axi_awqos),
                      .mem_axi_awregion(mem_axi_awregion),
                      .mem_axi_awuser(mem_axi_awuser),
                      .mem_axi_awvalid(mem_axi_awvalid),
                      .mem_axi_awready(mem_axi_awready),

                      // AXI Write Data Channel Signals
                      .mem_axi_wid(mem_axi_wid),
                      .mem_axi_wdata(mem_axi_wdata),
                      .mem_axi_wstrb(mem_axi_wstrb),
                      .mem_axi_wlast(mem_axi_wlast),
                      .mem_axi_wuser(mem_axi_wuser),
                      .mem_axi_wvalid(mem_axi_wvalid),
                      .mem_axi_wready(mem_axi_wready),

                      // AXI Read Address Channel Signals
                      .mem_axi_arid(mem_axi_arid),
                      .mem_axi_araddr(mem_axi_araddr),
                      .mem_axi_arlen(mem_axi_arlen),
                      .mem_axi_arsize(mem_axi_arsize),
                      .mem_axi_arburst(mem_axi_arburst),
                      .mem_axi_arlock(mem_axi_arlock),
                      .mem_axi_arcache(mem_axi_arcache),
                      .mem_axi_arprot(mem_axi_arprot),
                      .mem_axi_arqos(mem_axi_arqos),
                      .mem_axi_arregion(mem_axi_arregion),
                      .mem_axi_aruser(mem_axi_aruser),
                      .mem_axi_arvalid(mem_axi_arvalid),
                      .mem_axi_arready(mem_axi_arready),

                      // AXI Read Data Channel Signals
                      .mem_axi_rid(mem_axi_rid),
                      .mem_axi_rdata(mem_axi_rdata),
                      .mem_axi_rresp(mem_axi_rresp),
                      .mem_axi_rlast(mem_axi_rlast),
                      .mem_axi_ruser(mem_axi_ruser),
                      .mem_axi_rvalid(mem_axi_rvalid),
                      .mem_axi_rready(mem_axi_rready),

                      // AXI Write Response Channel Signals
                      .mem_axi_bid(mem_axi_bid),
                      .mem_axi_bresp(mem_axi_bresp),
                      .mem_axi_buser(mem_axi_buser),
                      .mem_axi_bvalid(mem_axi_bvalid),
                      .mem_axi_bready(mem_axi_bready),

                      .eth_axi_araddr(eth_axi_araddr),
                      .eth_axi_arburst(eth_axi_arburst),
                      .eth_axi_arcache(eth_axi_arcache),
                      .eth_axi_arid(eth_axi_arid),
                      .eth_axi_arlen(eth_axi_arlen),
                      .eth_axi_arlock(eth_axi_arlock),
                      .eth_axi_arprot(eth_axi_arprot),
                      // .eth_axi_arqos(eth_axi_arqos),
                      .eth_axi_arready(eth_axi_arready),
                      .eth_axi_arsize(eth_axi_arsize),
                      // .eth_axi_aruser(eth_axi_aruser),
                      .eth_axi_arvalid(eth_axi_arvalid),

                      .eth_axi_awaddr(eth_axi_awaddr),
                      .eth_axi_awburst(eth_axi_awburst),
                      .eth_axi_awcache(eth_axi_awcache),
                      .eth_axi_awid(eth_axi_awid),
                      .eth_axi_awlen(eth_axi_awlen),
                      .eth_axi_awlock(eth_axi_awlock),
                      .eth_axi_awprot(eth_axi_awprot),
                      // .eth_axi_awqos(eth_axi_awqos),
                      .eth_axi_awready(eth_axi_awready),
                      .eth_axi_awsize(eth_axi_awsize),
                      // .eth_axi_awuser(eth_axi_awuser),
                      .eth_axi_awvalid(eth_axi_awvalid),

                      .eth_axi_bid(eth_axi_bid),
                      .eth_axi_bready(eth_axi_bready),
                      .eth_axi_bresp(eth_axi_bresp),
                      // .eth_axi_buser(eth_axi_buser),
                      .eth_axi_bvalid(eth_axi_bvalid),

                      .eth_axi_rdata(eth_axi_rdata),
                      .eth_axi_rid(eth_axi_rid),
                      .eth_axi_rlast(eth_axi_rlast),
                      .eth_axi_rready(eth_axi_rready),
                      .eth_axi_rresp(eth_axi_rresp),
                      // .eth_axi_ruser(eth_axi_ruser),
                      .eth_axi_rvalid(eth_axi_rvalid),

                      .eth_axi_wdata(eth_axi_wdata),
                      .eth_axi_wlast(eth_axi_wlast),
                      .eth_axi_wready(eth_axi_wready),
                      .eth_axi_wstrb(eth_axi_wstrb),
                      // .eth_axi_wuser(eth_axi_wuser),
                      .eth_axi_wvalid(eth_axi_wvalid),

                      .sram_axi_araddr(sram_axi_araddr),
                      .sram_axi_arburst(sram_axi_arburst),
                      .sram_axi_arcache(sram_axi_arcache),
                      .sram_axi_arid(sram_axi_arid),
                      .sram_axi_arlen(sram_axi_arlen),
                      .sram_axi_arlock(sram_axi_arlock),
                      .sram_axi_arprot(sram_axi_arprot),
                      // .sram_axi_arqos(sram_axi_arqos),
                      .sram_axi_arready(sram_axi_arready),
                      .sram_axi_arsize(sram_axi_arsize),
                      // .sram_axi_aruser(sram_axi_aruser),
                      .sram_axi_arvalid(sram_axi_arvalid),

                      .sram_axi_awaddr(sram_axi_awaddr),
                      .sram_axi_awburst(sram_axi_awburst),
                      .sram_axi_awcache(sram_axi_awcache),
                      .sram_axi_awid(sram_axi_awid),
                      .sram_axi_awlen(sram_axi_awlen),
                      .sram_axi_awlock(sram_axi_awlock),
                      .sram_axi_awprot(sram_axi_awprot),
                      // .sram_axi_awqos(sram_axi_awqos),
                      .sram_axi_awready(sram_axi_awready),
                      .sram_axi_awsize(sram_axi_awsize),
                      // .sram_axi_awuser(sram_axi_awuser),
                      .sram_axi_awvalid(sram_axi_awvalid),

                      .sram_axi_bid(sram_axi_bid),
                      .sram_axi_bready(sram_axi_bready),
                      .sram_axi_bresp(sram_axi_bresp),
                      // .sram_axi_buser(sram_axi_buser),
                      .sram_axi_bvalid(sram_axi_bvalid),

                      .sram_axi_rdata(sram_axi_rdata),
                      .sram_axi_rid(sram_axi_rid),
                      .sram_axi_rlast(sram_axi_rlast),
                      .sram_axi_rready(sram_axi_rready),
                      .sram_axi_rresp(sram_axi_rresp),
                      // .sram_axi_ruser(sram_axi_ruser),
                      .sram_axi_rvalid(sram_axi_rvalid),

                      .sram_axi_wdata(sram_axi_wdata),
                      .sram_axi_wlast(sram_axi_wlast),
                      .sram_axi_wready(sram_axi_wready),
                      .sram_axi_wstrb(sram_axi_wstrb),
                      // .sram_axi_wuser(sram_axi_wuser),
                      .sram_axi_wvalid(sram_axi_wvalid),

                      .ddr_ready(init_calib_complete),

                      .uart_tx(uart_tx),
                      .uart_rx(uart_rx)


                    );

endmodule
