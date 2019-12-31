`default_nettype none

module Top  #(parameter HDISP = 800, parameter VDISP = 480)(
    // Les signaux externes de la partie FPGA
	input  wire         FPGA_CLK1_50,
	input  wire  [1:0]	KEY,
	output logic [7:0]	LED,
	input  wire	 [3:0]	SW,
    // Les signaux du support matériel son regroupés dans une interface
    hws_if.master       hws_ifm,
		video_if.master     video_ifm
);

//====================================
//  Déclarations des signaux internes
//====================================
  wire        sys_rst;   // Le signal de reset du système
  wire        sys_clk;   // L'horloge système a 100Mhz
  wire        pixel_clk; // L'horloge de la video 32 Mhz

//=======================================================
//  La PLL pour la génération des horloges
//=======================================================

sys_pll  sys_pll_inst(
		   .refclk(FPGA_CLK1_50),   // refclk.clk
		   .rst(1'b0),              // pas de reset
		   .outclk_0(pixel_clk),    // horloge pixels a 32 Mhz
		   .outclk_1(sys_clk)       // horloge systeme a 100MHz
);

//=============================
//  Les bus Wishbone internes
//=============================
wshb_if #( .DATA_BYTES(4)) wshb_if_sdram  (sys_clk, sys_rst);
wshb_if #( .DATA_BYTES(4)) wshb_if_stream (sys_clk, sys_rst);

//=============================
//  Le support matériel
//=============================
`ifndef SIMULATION
hw_support hw_support_inst (
    .wshb_ifs (wshb_if_sdram),
    .wshb_ifm (wshb_if_stream),
    .hws_ifm  (hws_ifm),
	.sys_rst  (), // output
    .SW_0     ( SW[0] ),
    .KEY      ( KEY )
 );
`endif

//=============================
// On neutralise l'interface
// du flux video pour l'instant
// A SUPPRIMER PLUS TARD
//=============================
assign wshb_if_stream.ack = 1'b1;
assign wshb_if_stream.dat_sm = '0 ;
assign wshb_if_stream.err =  1'b0 ;
assign wshb_if_stream.rty =  1'b0 ;

/*
//=============================
// On neutralise l'interface SDRAM
// pour l'instant
// A SUPPRIMER PLUS TARD
//=============================
assign wshb_if_sdram.stb  = 1'b0;
assign wshb_if_sdram.cyc  = 1'b0;
assign wshb_if_sdram.we   = 1'b0;
assign wshb_if_sdram.adr  = '0  ;
assign wshb_if_sdram.dat_ms = '0 ;
assign wshb_if_sdram.sel = '0 ;
assign wshb_if_sdram.cti = '0 ;
assign wshb_if_sdram.bte = '0 ;
*/

//--------------------------
//------- Code Eleves ------
//--------------------------

/** SQUELETTE DU PROJET **/

`ifdef SIMULATION
  localparam MAX_CNT_1=50 ;
`else
  localparam MAX_CNT_1=50000000 ;
`endif

localparam CNT_WIDTH_1 = $clog2(MAX_CNT_1);

logic[CNT_WIDTH_1-1:0] cnt_1;

assign sys_rst = !KEY[0];
assign LED[0] = sys_rst;


always_ff @ (posedge sys_clk) begin
	if(sys_rst)
	begin
		cnt_1 = 0;
		LED[1] <= 0;
	end
	else
	begin
		cnt_1 <= (cnt_1==MAX_CNT_1-1) ? 0 : cnt_1+1;
		if(cnt_1 == MAX_CNT_1-1) LED[1] <= !LED[1];
	end
end

// Gestion du pxl_rst

logic pixel_rst;
logic pixel_rst_buffer;

always_ff@(posedge pixel_clk or posedge sys_rst)
if(sys_rst)
begin
	pixel_rst_buffer <= 1;
	pixel_rst <= 1;
end
else
begin
	pixel_rst_buffer <= 0;
	pixel_rst <= pixel_rst_buffer;
end

// Nouveau compteur

`ifdef SIMULATION
  localparam MAX_CNT_2=16 ;
`else
  localparam MAX_CNT_2=16000000 ;
`endif

localparam CNT_WIDTH_2 = $clog2(MAX_CNT_2);

logic[CNT_WIDTH_2-1:0] cnt_2;


always_ff @ (posedge pixel_clk) begin
	if(pixel_rst)
	begin
		cnt_2 = 0;
		LED[2] <= 0;
	end
	else
	begin
		cnt_2 <= (cnt_2==MAX_CNT_2-1) ? 0 : cnt_2+1;
		if(cnt_2 == MAX_CNT_2-1) LED[2] <= !LED[2];
	end
end

/** CONTROLLEUR VIDEO **/

vga #( .HDISP(HDISP), .VDISP(VDISP)) vga_controller (
	.pixel_clk(pixel_clk),
	.pixel_rst(pixel_rst),
	.video_ifm(video_ifm),
	.wshb_ifm(wshb_if_sdram)
);

endmodule
