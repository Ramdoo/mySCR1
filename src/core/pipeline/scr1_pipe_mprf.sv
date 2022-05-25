/// Copyright by Syntacore LLC © 2016-2021. See LICENSE for details
/// @file       <scr1_pipe_mprf.sv>
/// @brief      Multi Port Register File (MPRF)
///

`include "scr1_arch_description.svh"
`include "scr1_arch_types.svh"

module scr1_pipe_mprf (
    // Common
`ifdef SCR1_MPRF_RST_EN
    input   logic                               rst_n,                      // MPRF reset
`endif // SCR1_MPRF_RST_EN
    input   logic                               clk,                        // MPRF clock

    // EXU <-> MPRF interface
    input   logic [`SCR1_MPRF_AWIDTH-1:0]       exu2mprf_rs1_addr_i,        // MPRF rs1 read address
    output  logic [`SCR1_XLEN-1:0]              mprf2exu_rs1_data_o,        // MPRF rs1 read data
    input   logic [`SCR1_MPRF_AWIDTH-1:0]       exu2mprf_rs2_addr_i,        // MPRF rs2 read address
    output  logic [`SCR1_XLEN-1:0]              mprf2exu_rs2_data_o,        // MPRF rs2 read data
    input   logic                               exu2mprf_w_req_i,           // MPRF write request
    input   logic [`SCR1_MPRF_AWIDTH-1:0]       exu2mprf_rd_addr_i,         // MPRF rd write address
    input   logic [`SCR1_XLEN-1:0]              exu2mprf_rd_data_i          // MPRF rd write data
);

//-------------------------------------------------------------------------------
// Local types declaration
//-------------------------------------------------------------------------------

logic                        wr_req_vd;

logic                        rs1_addr_vd;
logic                        rs2_addr_vd;

`ifdef  SCR1_MPRF_RAM
logic                        rs1_addr_vd_ff;
logic                        rs2_addr_vd_ff;

logic                        rs1_new_data_req;
logic                        rs2_new_data_req;
logic                        rs1_new_data_req_ff;
logic                        rs2_new_data_req_ff;
logic                        read_new_data_req;

logic    [`SCR1_XLEN-1:0]    rd_data_ff;

logic    [`SCR1_XLEN-1:0]    rs1_data_ff;
logic    [`SCR1_XLEN-1:0]    rs2_data_ff;

// when using RAM, 2 memories are needed because 3 simultaneous independent
// write/read operations can occur
 `ifdef SCR1_TRGT_FPGA_INTEL_MAX10
(* ramstyle = "M9K" *)      logic   [`SCR1_XLEN-1:0]    mprf_int   [1:`SCR1_MPRF_SIZE-1];
(* ramstyle = "M9K" *)      logic   [`SCR1_XLEN-1:0]    mprf_int2  [1:`SCR1_MPRF_SIZE-1];
 `elsif SCR1_TRGT_FPGA_INTEL_ARRIAV
(* ramstyle = "M10K" *)     logic   [`SCR1_XLEN-1:0]    mprf_int   [1:`SCR1_MPRF_SIZE-1];
(* ramstyle = "M10K" *)     logic   [`SCR1_XLEN-1:0]    mprf_int2  [1:`SCR1_MPRF_SIZE-1];
 `else
logic   [`SCR1_XLEN-1:0]    mprf_int   [1:`SCR1_MPRF_SIZE-1];
logic   [`SCR1_XLEN-1:0]    mprf_int2  [1:`SCR1_MPRF_SIZE-1];
 `endif
`else  // distributed logic implementation
type_scr1_mprf_v [1:`SCR1_MPRF_SIZE-1]                  mprf_int;
`endif

// Simulation friendly names
    wire [31:0] x0_zero_w = mprf_int[32'd0];
    wire [31:0] x1_ra_w   = mprf_int[32'd1];
    wire [31:0] x2_sp_w   = mprf_int[32'd2];
    wire [31:0] x3_gp_w   = mprf_int[32'd3];
    wire [31:0] x4_tp_w   = mprf_int[32'd4];
    wire [31:0] x5_t0_w   = mprf_int[32'd5];
    wire [31:0] x6_t1_w   = mprf_int[32'd6];
    wire [31:0] x7_t2_w   = mprf_int[32'd7];
    wire [31:0] x8_s0_w   = mprf_int[32'd8];
    wire [31:0] x9_s1_w   = mprf_int[32'd9];
    wire [31:0] x10_a0_w  = mprf_int[32'd10];
    wire [31:0] x11_a1_w  = mprf_int[32'd11];
    wire [31:0] x12_a2_w  = mprf_int[32'd12];
    wire [31:0] x13_a3_w  = mprf_int[32'd13];
    wire [31:0] x14_a4_w  = mprf_int[32'd14];
    wire [31:0] x15_a5_w  = mprf_int[32'd15];
    wire [31:0] x16_a6_w  = mprf_int[32'd16];
    wire [31:0] x17_a7_w  = mprf_int[32'd17];
    wire [31:0] x18_s2_w  = mprf_int[32'd18];
    wire [31:0] x19_s3_w  = mprf_int[32'd19];
    wire [31:0] x20_s4_w  = mprf_int[32'd20];
    wire [31:0] x21_s5_w  = mprf_int[32'd21];
    wire [31:0] x22_s6_w  = mprf_int[32'd22];
    wire [31:0] x23_s7_w  = mprf_int[32'd23];
    wire [31:0] x24_s8_w  = mprf_int[32'd24];
    wire [31:0] x25_s9_w  = mprf_int[32'd25];
    wire [31:0] x26_s10_w = mprf_int[32'd26];
    wire [31:0] x27_s11_w = mprf_int[32'd27];
    wire [31:0] x28_t3_w  = mprf_int[32'd28];
    wire [31:0] x29_t4_w  = mprf_int[32'd29];
    wire [31:0] x30_t5_w  = mprf_int[32'd30];
    wire [31:0] x31_t6_w  = mprf_int[32'd31];

//------------------------------------------------------------------------------
// MPRF control logic
//------------------------------------------------------------------------------

// control signals common for distributed logic and RAM implementations
assign  rs1_addr_vd  =   |exu2mprf_rs1_addr_i;
assign  rs2_addr_vd  =   |exu2mprf_rs2_addr_i;

assign  wr_req_vd  =   exu2mprf_w_req_i & |exu2mprf_rd_addr_i;

// RAM implementation specific control signals
`ifdef SCR1_MPRF_RAM
assign  rs1_new_data_req    =   wr_req_vd & ( exu2mprf_rs1_addr_i == exu2mprf_rd_addr_i );
assign  rs2_new_data_req    =   wr_req_vd & ( exu2mprf_rs2_addr_i == exu2mprf_rd_addr_i );
assign  read_new_data_req   =   rs1_new_data_req | rs2_new_data_req;

always_ff @( posedge clk ) begin
    rs1_addr_vd_ff          <=  rs1_addr_vd;
    rs2_addr_vd_ff          <=  rs2_addr_vd;
    rs1_new_data_req_ff     <=  rs1_new_data_req;
    rs2_new_data_req_ff     <=  rs2_new_data_req;
end
`endif // SCR1_MPRF_RAM

`ifdef  SCR1_MPRF_RAM
//-------------------------------------------------------------------------------
// RAM implementation
//-------------------------------------------------------------------------------

// RAM is implemented with 2 simple dual-port memories with sync read operation;
// logic for "write-first" RDW behavior is implemented externally to the embedded
// memory blocks

// bypass new wr_data to the read output if write/read collision occurs
assign  mprf2exu_rs1_data_o   =   ( rs1_new_data_req_ff ) ? rd_data_ff
                                : (( rs1_addr_vd_ff )   ? rs1_data_ff
                                                        : '0 );

assign  mprf2exu_rs2_data_o   =   ( rs2_new_data_req_ff ) ? rd_data_ff
                                : (( rs2_addr_vd_ff )   ? rs2_data_ff
                                                        : '0 );

always_ff @( posedge clk ) begin
    if ( read_new_data_req ) begin
        rd_data_ff     <=  exu2mprf_rd_data_i;
    end
end

// synchronous read operation
always_ff @( posedge clk ) begin
    rs1_data_ff   <=   mprf_int[exu2mprf_rs1_addr_i];
    rs2_data_ff   <=   mprf_int2[exu2mprf_rs2_addr_i];
end

// write operation
always_ff @( posedge clk ) begin
    if ( wr_req_vd ) begin
        mprf_int[exu2mprf_rd_addr_i]  <= exu2mprf_rd_data_i;
        mprf_int2[exu2mprf_rd_addr_i] <= exu2mprf_rd_data_i;
    end
end
`else   // distributed logic implementation
//------------------------------------------------------------------------------
// distributed logic implementation
//------------------------------------------------------------------------------

// asynchronous read operation
assign  mprf2exu_rs1_data_o = ( rs1_addr_vd ) ? mprf_int[exu2mprf_rs1_addr_i] : '0;
assign  mprf2exu_rs2_data_o = ( rs2_addr_vd ) ? mprf_int[exu2mprf_rs2_addr_i] : '0;

// write operation
 `ifdef SCR1_MPRF_RST_EN
always_ff @( posedge clk, negedge rst_n ) begin
    if ( ~rst_n ) begin
        mprf_int <= '{default: '0};
    end else if ( wr_req_vd ) begin
        mprf_int[exu2mprf_rd_addr_i] <= exu2mprf_rd_data_i;
    end
end
 `else // ~SCR1_MPRF_RST_EN
always_ff @( posedge clk ) begin
    if ( wr_req_vd ) begin
        mprf_int[exu2mprf_rd_addr_i] <= exu2mprf_rd_data_i;
    end
end
 `endif // ~SCR1_MPRF_RST_EN
`endif

`ifdef SCR1_TRGT_SIMULATION
//-------------------------------------------------------------------------------
// Assertion
//-------------------------------------------------------------------------------
`ifdef SCR1_MPRF_RST_EN
SCR1_SVA_MPRF_WRITEX : assert property (
    @(negedge clk) disable iff (~rst_n)
    exu2mprf_w_req_i |-> !$isunknown({exu2mprf_rd_addr_i, (|exu2mprf_rd_addr_i ? exu2mprf_rd_data_i : `SCR1_XLEN'd0)})
    ) else $error("MPRF error: unknown values");
`endif // SCR1_MPRF_RST_EN

`endif // SCR1_TRGT_SIMULATION

endmodule : scr1_pipe_mprf
