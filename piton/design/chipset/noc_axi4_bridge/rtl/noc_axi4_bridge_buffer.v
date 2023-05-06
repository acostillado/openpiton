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


module noc_axi4_bridge_buffer #(
    parameter SWAP_ENDIANESS = 0, // swap endianess, needed when used in conjunction with a little endian core like Ariane
    parameter ADDR_OFFSET = 64'h0,
    // Control of Rd/Wr responses order. Being enabled, enforces Rd/Wr response order to the NOC the same as Rd/Wr requests came from the NOC.
    // The feature was implemented because of bug not yet discovered in noc_axi4_brodge_ser. It made looking OP as not tolerant to Rd/Wr reordering,
    // what became not true after bug fix. Anyway the feature is left as fully tested and functionable but assumes the possibility of 
    // "Rd/Wr AXI ID thread deadlock" if multiple IDs are used. A detection of such event is implemented, but was never met from connected
    // HBM/DDR/BRAM/URAM memories before the above bug fix and after.
    parameter RDWR_INORDER = 0,
    parameter NUM_REQ_OUTSTANDING = 4,
    parameter NUM_REQ_MSHRID_LBIT = 0,
    parameter NUM_REQ_MSHRID_BITS = 0,
    parameter NUM_REQ_YTHREADS = 1,
    parameter NUM_REQ_XTHREADS = 1
) (
  input clk,
  input rst_n,
  input uart_boot_en, 
  output reg axi_id_deadlock,

  // from deserializer
  input [`MSG_HEADER_WIDTH-1:0] deser_header,
  input [`AXI4_DATA_WIDTH -1:0] deser_data,
  input  deser_val,
  output deser_rdy,

  // read request out
  output [`AXI4_ADDR_WIDTH-1:0] read_req_addr,
  output [`AXI4_ID_WIDTH  -1:0] read_req_id,
  output read_req_val,
  input  read_req_rdy,

  // read response in
  input [`AXI4_DATA_WIDTH-1:0] read_resp_data,
  input [`AXI4_ID_WIDTH  -1:0] read_resp_id,
  input  read_resp_val,
  output read_resp_rdy,

  // read request out
  output [`AXI4_ADDR_WIDTH-1:0] write_req_addr,
  output [`AXI4_ID_WIDTH  -1:0] write_req_id,
  output [`AXI4_DATA_WIDTH-1:0] write_req_data,
  output [`AXI4_STRB_WIDTH-1:0] write_req_strb,
  output write_req_val,
  input  write_req_rdy,

  // read response in
  input [`AXI4_ID_WIDTH-1:0] write_resp_id,
  input  write_resp_val,
  output write_resp_rdy,

  // in serializer
  output [`MSG_HEADER_WIDTH-1:0] ser_header,
  output [`AXI4_DATA_WIDTH -1:0] ser_data,
  output ser_val,
  input  ser_rdy
);

localparam INVALID = 1'd0;
localparam WAITING = 1'd1;

localparam READ  = 1'd0;
localparam WRITE = 1'd1;


reg [`NOC_AXI4_BRIDGE_IN_FLIGHT_LIMIT-1:0]                          pkt_state_buf ;
reg [`MSG_HEADER_WIDTH-1:0]   pkt_header[`NOC_AXI4_BRIDGE_IN_FLIGHT_LIMIT-1:0];
reg [`NOC_AXI4_BRIDGE_IN_FLIGHT_LIMIT-1:0]                          pkt_command;

reg [`NOC_AXI4_BRIDGE_BUFFER_ADDR_SIZE-1:0]    fifo_in;
reg [`NOC_AXI4_BRIDGE_BUFFER_ADDR_SIZE-1:0]    fifo_out;

wire deser_go = (deser_rdy & deser_val);
wire read_req_go = (read_req_val & read_req_rdy);
// wire read_resp_go = (read_resp_val & read_resp_rdy);
wire write_req_go = (write_req_val & write_req_rdy);
// wire write_resp_go = (write_resp_val & write_resp_rdy);
wire req_go = read_req_go || write_req_go;
wire ser_go = ser_val & ser_rdy;

//
//  SEND REQUESTS 
//

always @(posedge clk) begin
    if(~rst_n) begin
        fifo_in <= {`NOC_AXI4_BRIDGE_BUFFER_ADDR_SIZE{1'b0}};
        fifo_out <= {`NOC_AXI4_BRIDGE_BUFFER_ADDR_SIZE{1'b0}};
    end 
    else begin
        fifo_in <= deser_go ? fifo_in + 1 : fifo_in;
        fifo_out <= req_go ? fifo_out + 1 : fifo_out;
    end
end


genvar i;
generate 
    for (i = 0; i < `NOC_AXI4_BRIDGE_IN_FLIGHT_LIMIT; i = i + 1) begin
        always @(posedge clk) begin
            if(~rst_n) begin
                pkt_state_buf[i] <= INVALID;
                pkt_header[i] <= `MSG_HEADER_WIDTH'b0;
                pkt_command[i] <= 1'b0;
            end 
            else begin
                if ((i == fifo_in) & deser_go) begin
                    pkt_state_buf[i] <= WAITING;
                    pkt_header[i] <= deser_header;
                    pkt_command[i] <= (deser_header[`MSG_TYPE] == `MSG_TYPE_STORE_MEM) 
                                   || (deser_header[`MSG_TYPE] == `MSG_TYPE_NC_STORE_REQ);
                end
                else if ((i == fifo_out) & req_go)
                    pkt_state_buf[i] <= INVALID;
            end
        end
    end
endgenerate

reg req_val;
always @(posedge clk)
  if(~rst_n) req_val <= 1'b0;
  else       req_val <= (pkt_state_buf[fifo_out] == WAITING && !req_go);

assign deser_rdy = (pkt_state_buf[fifo_in] == INVALID);
wire [`AXI4_DATA_WIDTH-1:0] wdata;

// Xilinx-synthesizable Simple Dual Port Single Clock RAM
xilinx_simple_dual_port_1_clock_ram #(
    .RAM_WIDTH(`AXI4_DATA_WIDTH),                 // Specify RAM data width
    .RAM_DEPTH(`NOC_AXI4_BRIDGE_IN_FLIGHT_LIMIT), // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("LOW_LATENCY")               // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
) noc_axi4_bridge_sram_data (
    .addra(fifo_in),        // Write address bus, width determined from RAM_DEPTH
    .addrb(fifo_out),       // Read address bus, width determined from RAM_DEPTH
    .dina(deser_data),      // RAM input data, width determined from RAM_WIDTH
    .clka(clk),             // Clock
    .wea(deser_go),         // Write enable
    .enb(1'b1),             // Read Enable, for additional power savings, disable when not in use
    .rstb(~rst_n),          // Output reset (does not affect memory contents)
    .regceb(1'b1),          // Output register enable
    .doutb(wdata)           // RAM output data, width determined from RAM_WIDTH
);

wire [`MSG_HEADER_WIDTH-1 :0] req_header  = pkt_header[fifo_out];

wire [`MSG_SRC_CHIPID_WIDTH-1:0] src_chipid = req_header[`MSG_SRC_CHIPID];
wire [`MSG_SRC_X_WIDTH     -1:0] src_x      = req_header[`MSG_SRC_X];
wire [`MSG_SRC_Y_WIDTH     -1:0] src_y      = req_header[`MSG_SRC_Y];
wire [`MSG_SRC_FBITS_WIDTH -1:0] src_fbits  = req_header[`MSG_SRC_FBITS];
wire [`MSG_SRC_X_WIDTH     -1:0] ini_x      = req_header[`MSG_SRC_X];
wire [`MSG_SRC_Y_WIDTH     -1:0] ini_y      = req_header[`MSG_SRC_Y];

wire [`MSG_DST_CHIPID_WIDTH-1:0] dst_chipid = req_header[`MSG_DST_CHIPID];
wire [`MSG_DST_X_WIDTH     -1:0] dst_x      = req_header[`MSG_DST_X];
wire [`MSG_DST_Y_WIDTH     -1:0] dst_y      = req_header[`MSG_DST_Y];
wire [`MSG_DST_FBITS_WIDTH -1:0] dst_fbits  = req_header[`MSG_DST_FBITS];

wire [`MSG_MSHRID_WIDTH    -1:0] mshrid     = req_header[`MSG_MSHRID];
wire [`MSG_LSID_WIDTH      -1:0] lsid       = req_header[`MSG_LSID];
wire [`MSG_SDID_WIDTH      -1:0] sdid       = req_header[`MSG_SDID];


wire [`PHY_ADDR_WIDTH -1:0] virt_addr = req_header[`MSG_ADDR];
wire [`AXI4_ADDR_WIDTH-1:0] phys_addr;

// If running uart tests - we need to do address translation
`ifdef PITONSYS_UART_BOOT
storage_addr_trans_unified   #(
`else
storage_addr_trans #(
`endif
.STORAGE_ADDR_WIDTH(`AXI4_ADDR_WIDTH)
) cpu_mig_addr_translator (
    .va_byte_addr       (virt_addr  ),
    .storage_addr_out   (phys_addr  )
);

wire [`AXI4_ADDR_WIDTH-1:0] addr = uart_boot_en ? {phys_addr[`AXI4_ADDR_WIDTH-4:0], 3'b0} : virt_addr - ADDR_OFFSET;
wire [`AXI4_ADDR_WIDTH-1:0] req_addr = {addr[`AXI4_ADDR_WIDTH-1:6], 6'b0};

assign read_req_addr  = req_addr;
assign write_req_addr = req_addr;


// Transformation of write data according to queueed request
reg [6:0] wr_size;
reg [$clog2(`AXI4_DATA_WIDTH/8)-1:0] wr_offset;
always @(*) extractSize(req_header, wr_size, wr_offset);

wire [`AXI4_DATA_WIDTH-1:0] wdata_swapped = SWAP_ENDIANESS ? swapData(wdata, wr_size) :
                                                                      wdata;

// wire [`AXI4_STRB_WIDTH-1:0] wstrb = ({`AXI4_STRB_WIDTH'h0,1'b1} << wr_size) -`AXI4_STRB_WIDTH'h1;
wire [`AXI4_STRB_WIDTH-1:0] wstrb = wr_size[0] ? { 1{1'b1}} :
                                    wr_size[1] ? { 2{1'b1}} :
                                    wr_size[2] ? { 4{1'b1}} :
                                    wr_size[3] ? { 8{1'b1}} :
                                    wr_size[4] ? {16{1'b1}} :
                                    wr_size[5] ? {32{1'b1}} :
                                    wr_size[6] ? {64{1'b1}} :
                                    `AXI4_DATA_WIDTH'h0;

assign write_req_data = wdata_swapped << (8*wr_offset);
assign write_req_strb = wstrb         <<    wr_offset;


//
// GET_RESPONSE
//

localparam NUM_REQ_OUTSTANDING_LOG2 = $clog2(NUM_REQ_OUTSTANDING);
localparam NUM_REQ_YTHREADS_LOG2    = $clog2(NUM_REQ_YTHREADS);
localparam NUM_REQ_XTHREADS_LOG2    = $clog2(NUM_REQ_XTHREADS);
localparam NUM_REQ_THREADS_LOG2 = NUM_REQ_YTHREADS_LOG2 + NUM_REQ_XTHREADS_LOG2 + NUM_REQ_MSHRID_BITS;
localparam NUM_REQ_THREADS = NUM_REQ_YTHREADS * NUM_REQ_XTHREADS * (1<<NUM_REQ_MSHRID_BITS) * (RDWR_INORDER ? 1:2); // read/write request type goes as an extension to thread ID if RDWR_INORDER=0 
localparam FULL_NUM_REQ_THREADS_LOG2 = $clog2(NUM_REQ_THREADS);

reg [NUM_REQ_OUTSTANDING_LOG2 : 0] outstnd_vrt_wrptrs[NUM_REQ_THREADS-1 : 0];
reg [NUM_REQ_OUTSTANDING_LOG2 : 0] outstnd_vrt_rdptrs[NUM_REQ_THREADS-1 : 0];

reg [NUM_REQ_THREADS-1         : 0] outstnd_vrt_empts;
reg [FULL_NUM_REQ_THREADS_LOG2 : 0] itr_empt;
always @(*)
  for (itr_empt = 0; itr_empt < NUM_REQ_THREADS; itr_empt = itr_empt+1)
    outstnd_vrt_empts[itr_empt] = (outstnd_vrt_rdptrs[itr_empt] == outstnd_vrt_wrptrs[itr_empt]);


reg  [clip2zer(FULL_NUM_REQ_THREADS_LOG2-1) : 0] full_resp_id;
reg  [NUM_REQ_OUTSTANDING_LOG2-1 : 0] outstnd_abs_rdptrs[NUM_REQ_THREADS-1 : 0];
wire [NUM_REQ_OUTSTANDING_LOG2-1 : 0] outstnd_abs_rdptr = outstnd_abs_rdptrs[full_resp_id];

reg init_outstnd_mem;
always @(posedge clk)
  if(~rst_n) init_outstnd_mem <= 1'b1;
  else if (outstnd_abs_rdptr == {NUM_REQ_OUTSTANDING_LOG2{1'b1}}) init_outstnd_mem <= 1'b0;


reg [NUM_REQ_THREADS-1 : 0]  outstnd_abs_rdptrs_val;
wire outstnd_abs_rdptr_val = outstnd_abs_rdptrs_val[full_resp_id];
wire outstnd_vrt_empt      = outstnd_vrt_empts     [full_resp_id];
reg [NUM_REQ_THREADS-1 : 0]  outstnd_command; // the vector stores the latest command type for particular ID, needed and effective only in RDWR_INORDER mode
wire [clip2zer(FULL_NUM_REQ_THREADS_LOG2-1) : 0] full_rd_resp_id = ({1'b0,{FULL_NUM_REQ_THREADS_LOG2{READ }}} << NUM_REQ_THREADS_LOG2) | (read_resp_id  & ((1<< NUM_REQ_THREADS_LOG2)-1));
wire [clip2zer(FULL_NUM_REQ_THREADS_LOG2-1) : 0] full_wr_resp_id = ({1'b0,{FULL_NUM_REQ_THREADS_LOG2{WRITE}}} << NUM_REQ_THREADS_LOG2) | (write_resp_id & ((1<< NUM_REQ_THREADS_LOG2)-1));
// masking outstnd_command by RDWR_INORDER just to reduce extra-logic (outstnd_command is not effective if RDWR_INORDER=0 anyway)
wire read_resp_val_act  = read_resp_val  && (!RDWR_INORDER || (!outstnd_command[full_rd_resp_id] && outstnd_abs_rdptrs_val[full_rd_resp_id]));
wire write_resp_val_act = write_resp_val && (!RDWR_INORDER || ( outstnd_command[full_wr_resp_id] && outstnd_abs_rdptrs_val[full_wr_resp_id]));
reg resp_val;
always @(posedge clk)
  if(~rst_n || init_outstnd_mem) begin 
    full_resp_id <= {1'b0,{FULL_NUM_REQ_THREADS_LOG2{1'b0}}};
    resp_val <= 1'b0;
    axi_id_deadlock <= 1'b0;
  end
  else begin
    if (outstnd_vrt_empt || outstnd_abs_rdptr_val) begin
      // Higher priority for Read response in case we have not already started working with the Write response ID some earlier,
      // In order to change priority two following strings should be exchanged (the condition is symmetrical)
      if (write_resp_val_act && !(read_resp_val_act  && full_resp_id == full_rd_resp_id)) full_resp_id <= full_wr_resp_id;
      if (read_resp_val_act  && !(write_resp_val_act && full_resp_id == full_wr_resp_id)) full_resp_id <= full_rd_resp_id;

      if (write_resp_val_act ||
          read_resp_val_act) resp_val <= 1'b1;

      // Catching "Rd/Wr AXI ID thread deadlock" possible in RDWR_INORDER mode with multiple IDs:
      // both Rd and Wr responses simultaneously don't correspond to expected inorder ones.
      // Masking the condition by RDWR_INORDER just to reduce extra-logic (outstnd_command is not effective if RDWR_INORDER=0 anyway)
      if (read_resp_val  &&  outstnd_command[full_rd_resp_id] && outstnd_abs_rdptrs_val[full_rd_resp_id] &&
          write_resp_val && !outstnd_command[full_wr_resp_id] && outstnd_abs_rdptrs_val[full_wr_resp_id] && RDWR_INORDER)
        axi_id_deadlock <= 1'b1;
    end
    if (ser_go)              resp_val <= 1'b0;
  end


localparam OUTSTND_HDR_WIDTH = (NUM_REQ_OUTSTANDING_LOG2+1) + NUM_REQ_OUTSTANDING_LOG2 + 1 + `MSG_HEADER_WIDTH;
wire [OUTSTND_HDR_WIDTH-1 : 0] clean_header;
wire req_occup = clean_header[`MSG_HEADER_WIDTH];

reg  [NUM_REQ_OUTSTANDING_LOG2-1 : 0] outstnd_abs_wrptr;
wire [NUM_REQ_OUTSTANDING_LOG2-1 : 0] outstnd_abs_wrptr_mem = outstnd_abs_wrptr + {{(NUM_REQ_OUTSTANDING_LOG2-1){1'b0}},
                                                                                   (~init_outstnd_mem & req_occup)};
always @(posedge clk)
  if(~rst_n) outstnd_abs_wrptr <= {NUM_REQ_OUTSTANDING_LOG2{1'b0}};
  else outstnd_abs_wrptr <= outstnd_abs_wrptr_mem; // searching for first free request location


wire req_command = pkt_command[fifo_out];
wire [`MSG_SRC_X_WIDTH -1:0] req_ini_x  = req_header[`MSG_SRC_X];
wire [`MSG_SRC_Y_WIDTH -1:0] req_ini_y  = req_header[`MSG_SRC_Y];
wire [`MSG_MSHRID_WIDTH-1:0] req_mshrid = req_header[`MSG_MSHRID];
wire [clip2zer(NUM_REQ_THREADS_LOG2-1):0] req_id = (((req_mshrid >> NUM_REQ_MSHRID_LBIT)
                                                                & ((1<< NUM_REQ_MSHRID_BITS  )-1)) << (NUM_REQ_YTHREADS_LOG2+
                                                                                                       NUM_REQ_XTHREADS_LOG2)) |
                                                   ((req_ini_y  & ((1<< NUM_REQ_YTHREADS_LOG2)-1)) <<  NUM_REQ_XTHREADS_LOG2)  |
                                                   ( req_ini_x  & ((1<< NUM_REQ_XTHREADS_LOG2)-1));
wire [clip2zer(FULL_NUM_REQ_THREADS_LOG2-1) : 0] full_req_id = ({1'b0,{FULL_NUM_REQ_THREADS_LOG2{req_command}}} << NUM_REQ_THREADS_LOG2) | req_id;

wire [OUTSTND_HDR_WIDTH-1 : 0] stor_header;
wire stor_command = (stor_header[`MSG_TYPE] == `MSG_TYPE_STORE_MEM) ||
                    (stor_header[`MSG_TYPE] == `MSG_TYPE_NC_STORE_REQ);
wire [`MSG_SRC_X_WIDTH -1:0] stor_ini_x  = stor_header[`MSG_SRC_X];
wire [`MSG_SRC_Y_WIDTH -1:0] stor_ini_y  = stor_header[`MSG_SRC_Y];
wire [`MSG_MSHRID_WIDTH-1:0] stor_mshrid = stor_header[`MSG_MSHRID];
wire [clip2zer(NUM_REQ_THREADS_LOG2-1):0] stor_id = (((stor_mshrid >> NUM_REQ_MSHRID_LBIT)
                                                                  & ((1<< NUM_REQ_MSHRID_BITS  )-1)) << (NUM_REQ_YTHREADS_LOG2+
                                                                                                         NUM_REQ_XTHREADS_LOG2)) |
                                                    ((stor_ini_y  & ((1<< NUM_REQ_YTHREADS_LOG2)-1)) <<  NUM_REQ_XTHREADS_LOG2)  |
                                                    ( stor_ini_x  & ((1<< NUM_REQ_XTHREADS_LOG2)-1));
wire [clip2zer(FULL_NUM_REQ_THREADS_LOG2-1) : 0] full_stor_id = ({1'b0,{FULL_NUM_REQ_THREADS_LOG2{stor_command}}} << NUM_REQ_THREADS_LOG2) | stor_id;

wire [NUM_REQ_OUTSTANDING_LOG2-1 : 0] outstnd_vrt_rdptr = outstnd_vrt_rdptrs[full_resp_id];
wire outstnd_vrt_rdptr_val = (outstnd_vrt_rdptr == stor_header[`MSG_HEADER_WIDTH+1 +: NUM_REQ_OUTSTANDING_LOG2] &&
                              full_resp_id == full_stor_id && stor_header[`MSG_HEADER_WIDTH]);
wire [NUM_REQ_OUTSTANDING_LOG2-1 : 0] outstnd_abs_rdptr_mem = outstnd_abs_rdptr + {{(NUM_REQ_OUTSTANDING_LOG2-1){1'b0}},
                                                                                   (~ outstnd_vrt_empt &
                                                                                    ~(outstnd_vrt_rdptr_val |
                                                                                      outstnd_abs_rdptr_val))};
reg  [NUM_REQ_OUTSTANDING_LOG2 : 0] outstnd_wrreq_cnt;
reg  [NUM_REQ_OUTSTANDING_LOG2 : 0] outstnd_rdreq_cnt;
reg  [NUM_REQ_OUTSTANDING_LOG2 : 0] outstnd_wrrsp_cnt;
reg  [NUM_REQ_OUTSTANDING_LOG2 : 0] outstnd_rdrsp_cnt;
wire [NUM_REQ_OUTSTANDING_LOG2 : 0] outstnd_rsp_cnt = stor_header[NUM_REQ_OUTSTANDING_LOG2 + `MSG_HEADER_WIDTH+1 +: NUM_REQ_OUTSTANDING_LOG2+1];
reg dbg_wr_reorder;
reg dbg_rd_reorder;
reg [FULL_NUM_REQ_THREADS_LOG2 : 0] itr_ptr;
always @(posedge clk)
  if(~rst_n) begin
    for (itr_ptr = 0; itr_ptr < NUM_REQ_THREADS; itr_ptr = itr_ptr+1) begin
      outstnd_vrt_wrptrs[itr_ptr] <= {(NUM_REQ_OUTSTANDING_LOG2+1){1'b0}};
      outstnd_vrt_rdptrs[itr_ptr] <= {(NUM_REQ_OUTSTANDING_LOG2+1){1'b0}};
      outstnd_abs_rdptrs[itr_ptr] <= { NUM_REQ_OUTSTANDING_LOG2   {1'b0}};
      outstnd_abs_rdptrs_val[itr_ptr] <= 1'b0;
      outstnd_wrreq_cnt <= {(NUM_REQ_OUTSTANDING_LOG2+1){1'b0}};
      outstnd_rdreq_cnt <= {(NUM_REQ_OUTSTANDING_LOG2+1){1'b0}};
      outstnd_wrrsp_cnt <= {(NUM_REQ_OUTSTANDING_LOG2+1){1'b0}};
      outstnd_rdrsp_cnt <= {(NUM_REQ_OUTSTANDING_LOG2+1){1'b0}};
      dbg_wr_reorder <= 1'b0;
      dbg_rd_reorder <= 1'b0;
    end
  end
  else begin
    if (req_go) begin 
      outstnd_vrt_wrptrs[full_req_id] <= outstnd_vrt_wrptrs[full_req_id] + 1;
      if (outstnd_vrt_empts[full_req_id]) begin
        outstnd_abs_rdptrs    [full_req_id] <= outstnd_abs_wrptr;
        outstnd_abs_rdptrs_val[full_req_id] <= 1'b1;
        outstnd_command       [full_req_id] <= req_command;
      end
      if (req_command) outstnd_wrreq_cnt <= outstnd_wrreq_cnt + 1;
      else             outstnd_rdreq_cnt <= outstnd_rdreq_cnt + 1;
    end
    if (!outstnd_vrt_empt) begin
      if (!outstnd_abs_rdptr_val && outstnd_vrt_rdptr_val) begin 
        outstnd_abs_rdptrs_val[full_resp_id] <= 1'b1;
        outstnd_command       [full_resp_id] <= stor_command;
      end
      // searching for the next valid request location for responded ID
      outstnd_abs_rdptrs[full_resp_id] <= outstnd_abs_rdptr_mem;
    end
    if (ser_go) begin 
      outstnd_vrt_rdptrs    [full_resp_id] <= outstnd_vrt_rdptrs[full_resp_id] + 1;
      outstnd_abs_rdptrs_val[full_resp_id] <= 1'b0;
      if (stor_command) begin
        dbg_wr_reorder <= outstnd_wrrsp_cnt != outstnd_rsp_cnt;
        outstnd_wrrsp_cnt <= outstnd_wrrsp_cnt + 1;
      end
      else begin
        dbg_rd_reorder <= outstnd_rdrsp_cnt != outstnd_rsp_cnt;
        outstnd_rdrsp_cnt <= outstnd_rdrsp_cnt + 1;
      end
    end
    // Initialization of Outstanding requests memory
    if (init_outstnd_mem) outstnd_abs_rdptrs[full_resp_id] <= outstnd_abs_rdptr + 1;
  end


assign read_req_val  = req_val && !req_command && !req_occup && !init_outstnd_mem;
assign read_req_id = req_id;

assign write_req_val = req_val &&  req_command && !req_occup && !init_outstnd_mem;
assign write_req_id = req_id;

wire [NUM_REQ_OUTSTANDING_LOG2-1 : 0] outstnd_vrt_wrptr = outstnd_vrt_wrptrs[full_req_id];
wire [NUM_REQ_OUTSTANDING_LOG2   : 0] outstnd_req_cnt = req_command ? outstnd_wrreq_cnt :
                                                                      outstnd_rdreq_cnt;

// Xilinx-synthesizable True Dual Port RAM, Write_First, Single Clock
xilinx_true_dual_port_write_first_1_clock_ram #(
    .RAM_WIDTH(OUTSTND_HDR_WIDTH),    // Specify RAM data width
    .RAM_DEPTH(NUM_REQ_OUTSTANDING),  // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("LOW_LATENCY")   // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
) outstnd_req_mem (
    .addra(outstnd_abs_rdptr_mem),    // Port A address bus, width determined from RAM_DEPTH
    .addrb(outstnd_abs_wrptr_mem),    // Port B address bus, width determined from RAM_DEPTH
    .dina({OUTSTND_HDR_WIDTH{1'b0}}), // Port A RAM input data, width determined from RAM_WIDTH
    .dinb({outstnd_req_cnt,outstnd_vrt_wrptr,1'b1,req_header}), // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk),                       // Clock
    .wea(ser_go | init_outstnd_mem),  // Port A write enable
    .web(req_go),                     // Port B write enable
    .ena(1'b1),                       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),                       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(~rst_n),                    // Port A output reset (does not affect memory contents)
    .rstb(~rst_n),                    // Port B output reset (does not affect memory contents)
    .regcea(1'b1),                    // Port A output register enable
    .regceb(1'b1),                    // Port B output register enable
    .douta(stor_header),              // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(clean_header)              // Port B RAM output data, width determined from RAM_WIDTH
);

wire outstnd_abs_rdptr_val_act = outstnd_abs_rdptr_val & resp_val;
reg stor_hdr_val;
always @(posedge clk)
  if(~rst_n) stor_hdr_val <= 1'b0;
  else       stor_hdr_val <= outstnd_abs_rdptr_val_act;
wire stor_hdr_en = stor_hdr_val & outstnd_abs_rdptr_val_act;

assign read_resp_rdy  = stor_hdr_en & ser_rdy & ~stor_command;
assign write_resp_rdy = stor_hdr_en & ser_rdy &  stor_command;

// Transformation of read data according to outstanded request
reg [6:0] rd_size;
reg [$clog2(`AXI4_DATA_WIDTH/8)-1:0] rd_offset;
always @(*) extractSize(stor_header[`MSG_HEADER_WIDTH-1:0], rd_size, rd_offset);

wire [`AXI4_DATA_WIDTH-1:0] rdata_offseted = read_resp_data >> (8*rd_offset);
wire [`AXI4_DATA_WIDTH-1:0] rdata_swapped  = SWAP_ENDIANESS ? swapData(rdata_offseted, rd_size) :
                                                                       rdata_offseted;

wire [`AXI4_DATA_WIDTH-1:0] rdata = rd_size[0] ? {`AXI4_DATA_WIDTH/8  {rdata_swapped[7  :0]}} :
                                    rd_size[1] ? {`AXI4_DATA_WIDTH/16 {rdata_swapped[15 :0]}} :
                                    rd_size[2] ? {`AXI4_DATA_WIDTH/32 {rdata_swapped[31 :0]}} :
                                    rd_size[3] ? {`AXI4_DATA_WIDTH/64 {rdata_swapped[63 :0]}} :
                                    rd_size[4] ? {`AXI4_DATA_WIDTH/128{rdata_swapped[127:0]}} :
                                    rd_size[5] ? {`AXI4_DATA_WIDTH/256{rdata_swapped[255:0]}} :
                                    rd_size[6] ? {`AXI4_DATA_WIDTH/512{rdata_swapped[511:0]}} :
                                                  `AXI4_DATA_WIDTH'h0;

assign ser_val    = stor_hdr_en;
assign ser_data   = stor_command ? `AXI4_DATA_WIDTH'b0 : rdata;
assign ser_header = stor_header;


task automatic extractSize;
  input  [`MSG_HEADER_WIDTH-1 :0] header;
  output [6:0] size;
  output [$clog2(`AXI4_DATA_WIDTH/8)-1:0] offset;
  reg [`PHY_ADDR_WIDTH-1:0] virt_addr;
  reg uncacheable;
  begin
  virt_addr = header[`MSG_ADDR];
  uncacheable = (virt_addr[`PHY_ADDR_WIDTH-1]) ||
                (header[`MSG_TYPE] == `MSG_TYPE_NC_LOAD_REQ) ||
                (header[`MSG_TYPE] == `MSG_TYPE_NC_STORE_REQ);
  if (uncacheable)
    case (header[`MSG_DATA_SIZE])
      `MSG_DATA_SIZE_0B:  size = 7'd0;
      `MSG_DATA_SIZE_1B:  size = 7'd1;
      `MSG_DATA_SIZE_2B:  size = 7'd2;
      `MSG_DATA_SIZE_4B:  size = 7'd4;
      `MSG_DATA_SIZE_8B:  size = 7'd8;
      `MSG_DATA_SIZE_16B: size = 7'd16;
      `MSG_DATA_SIZE_32B: size = 7'd32;
      `MSG_DATA_SIZE_64B: size = 7'd64;
      default:            size = 7'b0; // should never end up here
    endcase
  else                    size = 7'd64;
  offset = uncacheable ? virt_addr : 0;
  end
endtask


function automatic [`AXI4_DATA_WIDTH-1:0] swapData;
  input [`AXI4_DATA_WIDTH-1:0] data;
  input [6:0] size;
  reg [$clog2(`AXI4_DATA_WIDTH/8)-1:0] swap_grnlty;
  reg [$clog2(`AXI4_DATA_WIDTH/8)  :0] itr_swp;
  begin
  // swap_grnlty = size - 7'h1;
  // the following code produces less LUTs
  swap_grnlty = size[0] ? 6'd0  :
                size[1] ? 6'd1  :
                size[2] ? 6'd3  :
                size[3] ? 6'd7  :
                size[4] ? 6'd15 :
                size[5] ? 6'd31 :
                          6'd63;
  swapData = `AXI4_DATA_WIDTH'h0;
  for (itr_swp = 0; itr_swp <= swap_grnlty; itr_swp = itr_swp+1)
    swapData[itr_swp*8 +: 8] = data[(swap_grnlty - itr_swp)*8 +: 8];
  end
endfunction


function integer clip2zer;
  input integer val;
  clip2zer = val < 0 ? 0 : val;
endfunction


/*
ila_buffer ila_buffer (
  .clk(clk), // input wire clk


  .probe0(deser_header), // input wire [191:0]  probe0  
  .probe1(deser_data), // input wire [511:0]  probe1 
  .probe2(deser_val), // input wire [0:0]  probe2 
  .probe3(deser_rdy), // input wire [0:0]  probe3 
  .probe4(ser_header), // input wire [191:0]  probe4 
  .probe5(ser_data), // input wire [511:0]  probe5 
  .probe6(ser_val), // input wire [0:0]  probe6 
  .probe7(ser_rdy), // input wire [0:0]  probe7 
  .probe8(req_header), // input wire [191:0]  probe8 
  .probe9(read_req_id), // input wire [1:0]  probe9 
  .probe10(read_req_val), // input wire [0:0]  probe10 
  .probe11(read_req_rdy), // input wire [0:0]  probe11 
  .probe12(read_resp_data), // input wire [511:0]  probe12 
  .probe13(read_resp_id), // input wire [1:0]  probe13 
  .probe14(read_resp_val), // input wire [0:0]  probe14 
  .probe15(read_resp_rdy), // input wire [0:0]  probe15 
  .probe16(req_header), // input wire [191:0]  probe16 
  .probe17(write_req_id), // input wire [1:0]  probe17 
  .probe18(write_req_data), // input wire [511:0]  probe18 
  .probe19(write_req_val), // input wire [0:0]  probe19 
  .probe20(write_req_rdy), // input wire [0:0]  probe20 
  .probe21(write_resp_id), // input wire [1:0]  probe21 
  .probe22(write_resp_val), // input wire [0:0]  probe22 
  .probe23(write_resp_rdy), // input wire [0:0]  probe23 
  .probe24(fifo_in), // input wire [1:0]  probe24 
  .probe25(fifo_out), // input wire [1:0]  probe25 
  .probe26(preser_arb), // input wire [0:0]  probe26 
  .probe27(bram_rdy), // input wire [3:0]  probe27 
  .probe28(ser_data_f), // input wire [511:0]  probe28 
  .probe29(ser_header_f), // input wire [191:0]  probe29 
  .probe30(ser_val_f), // input wire [0:0]  probe30 
  .probe31(ser_data_ff), // input wire [511:0]  probe31 
  .probe32(ser_header_ff), // input wire [191:0]  probe32 
  .probe33(ser_val_ff), // input wire [0:0]  probe33 
  .probe34(rst_n) // input wire [0:0]  probe34
);

reg [159:0] reqresp_count;
always @(posedge clk) begin
    if (~rst_n) begin
        reqresp_count <= 0;
    end
    else begin
        reqresp_count <= ser_go & deser_go ? reqresp_count     : 
                                   deser_go ? reqresp_count + 1 :
                                   ser_go ? reqresp_count - 1 : 
                                             reqresp_count;

    end
end

ila_axi_protocol_checker ila_axi_protocol_checker (
    .clk(clk), // input wire clk

    .probe0(rst_n), // input wire [0:0]  probe0  
    .probe1(reqresp_count) // input wire [159:0]  probe1
);
*/

endmodule
