module vga #(parameter HDISP = 800, parameter VDISP = 480) (
	input wire pixel_clk,
	input wire pixel_rst,
	video_if.master video_ifm,
	wshb_if.master  wshb_ifm
);



////////// PARAMETRES VGA ///////////

localparam HFP=40;
localparam HPULSE=48;
localparam HBP=40;
localparam VFP=13;
localparam VPULSE=3;
localparam VBP = 29;
localparam HCNT_SIZE = HFP+HPULSE+HBP+HDISP;
localparam VCNT_SIZE = VFP+VPULSE+VBP+VDISP;

////////// GESTION COMPTEURS REELS //////////

localparam HCNT_WIDTH = $clog2(HCNT_SIZE);
localparam VCNT_WIDTH = $clog2(VCNT_SIZE);

logic[HCNT_WIDTH-1:0] h_cnt;
logic[VCNT_WIDTH-1:0] v_cnt;

// Logique synchrone des compteurs
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
		v_cnt <= (v_cnt == VCNT_SIZE-1) ? 0 : v_cnt+1;
	end

end

////////// SIGNAUX DE CONTROLE VGA //////////

assign video_ifm.CLK = pixel_clk;
assign video_ifm.HS = !(h_cnt >= HFP && h_cnt < HFP+HPULSE);
assign video_ifm.VS = !(v_cnt >= VFP && v_cnt < VFP+VPULSE);
assign video_ifm.BLANK = (h_cnt >= HFP+HPULSE+HBP) && (v_cnt >= VFP+VPULSE+VBP);

////////// COMPTEURS GRAPHIQUES //////////

localparam XCNT_WIDTH = $clog2(HDISP);
localparam YCNT_WIDTH = $clog2(VDISP);

logic[XCNT_WIDTH-1:0] x_cnt;
logic[YCNT_WIDTH-1:0] y_cnt;

// Logique combinatoire (transposition si image existe)
assign x_cnt = video_ifm.BLANK ? h_cnt-(HFP+HPULSE+HBP) : 0;
assign y_cnt = video_ifm.BLANK ? v_cnt-(VFP+VPULSE+VBP) : 0;

////////// MIRE GRAPHIQUE //////////

assign video_ifm.RGB = (x_cnt[3:0] == 0) || (y_cnt[3:0] == 0) ? {3{8'b11111111}} : 0;

endmodule
