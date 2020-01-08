module vga #(parameter HDISP = 800, parameter VDISP = 480) (
	input wire pixel_clk,
	input wire pixel_rst,
	video_if.master video_ifm,
	wshb_if.master  wshb_ifm
);


/** ASSIGNATION DES SIGNAUX MAITRES **/
/*
assign wshb_ifm.dat_ms = 32'hBABECAFE;
assign wshb_ifm.adr = '0;
assign wshb_ifm.cyc = 1'b1;
assign wshb_ifm.sel = 4'b1111;
assign wshb_ifm.stb = 1'b1;
assign wshb_ifm.we = 1'b1;
assign wshb_ifm.cti = '0;
assign wshb_ifm.bte = '0;
*/


/** GENERATION DES SIGNAUX **/

localparam HFP=40;
localparam HPULSE=48;
localparam HBP=40;
localparam VFP=13;
localparam VPULSE=3;
localparam VBP = 29;
localparam HCNT_SIZE = HFP+HPULSE+HBP+HDISP;
localparam VCNT_SIZE = VFP+VPULSE+VBP+VDISP;
localparam HCNT_WIDTH = $clog2(HCNT_SIZE);
localparam VCNT_WIDTH = $clog2(VCNT_SIZE);

logic[HCNT_WIDTH-1:0] h_cnt;
logic[VCNT_WIDTH-1:0] v_cnt;

assign video_ifm.CLK = pixel_clk;

// Gestion des compteurs
always_ff @ (posedge pixel_clk)
if(pixel_rst)
begin
	h_cnt <= 0;
	v_cnt <= 0;
end
else
begin
	h_cnt <= h_cnt+1;
	if(h_cnt == HCNT_SIZE-1)
	begin
		h_cnt <= 0;
		v_cnt <= v_cnt+1;
	end

	if(v_cnt == VCNT_SIZE-1)
		v_cnt <= 0;
end

// Génération des signaux videos
assign video_ifm.HS = !(h_cnt >= HFP && h_cnt < HFP+HPULSE);
assign video_ifm.VS = !(v_cnt >= VFP && v_cnt < VFP+VPULSE);
assign video_ifm.BLANK = (h_cnt >= HFP+HPULSE+HBP) && (v_cnt >= VFP+VPULSE+VBP);

/** GENERATION DE LA MIRE **/

localparam XCNT_WIDTH = $clog2(HDISP);
localparam YCNT_WIDTH = $clog2(VDISP);
logic[XCNT_WIDTH-1:0] x_cnt;
logic[YCNT_WIDTH-1:0] y_cnt;

// Gestion des nouveaux compteurs
always_comb
begin
	if(!video_ifm.BLANK)
	begin
		x_cnt = 0;
		y_cnt = 0;
	end
	else
	begin
		x_cnt = h_cnt-(HFP+HPULSE+HBP);
		y_cnt = v_cnt-(VFP+VPULSE+VBP);
	end
end

// Génération de la grille
assign video_ifm.RGB = (x_cnt[3:0] == 0) || (y_cnt[3:0] == 0) ? 255 : 0;

logic [31:0] word;
logic[XCNT_WIDTH-1:0] x_cnt_sdram;
logic[YCNT_WIDTH-1:0] y_cnt_sdram;
//** LECTURE EN SDRAM **//
always_ff @ (posedge wshb_ifm.clk)
if(wshb_ifm.rst)
begin
	word <= 0;
	x_cnt_sdram <= 0;
	y_cnt_sdram <= 0;
end
else
begin
	if(wshb_ifm.ack)
	begin
		word <= wshb_ifm.dat_sm;

		// Mise à jour des compteurs
		x_cnt_sdram <= x_cnt_sdram+1;
		if(x_cnt_sdram == HDISP-1)
		begin
			x_cnt_sdram <= 0;
			y_cnt_sdram <= y_cnt_sdram+1;
		end

		if(y_cnt_sdram == VDISP-1)
			y_cnt_sdram <= 0;
	end
end

assign wshb_ifm.adr = (x_cnt_sdram + y_cnt_sdram*HDISP)*4;
assign wshb_ifm.we = 0'b0;
assign wshb_ifm.cyc = 1'b1;
assign wshb_ifm.sel = 4'b1111;
assign wshb_ifm.stb = 1'b1;
assign wshb_ifm.cti = '0;
assign wshb_ifm.bte = '0;

endmodule
