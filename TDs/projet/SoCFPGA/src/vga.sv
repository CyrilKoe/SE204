module vga #(parameter HDISP = 800, parameter VDISP = 480) (
	input wire pixel_clk,
	input wire pixel_rst,
	video_if.master video_ifm,
	wshb_if.master  wshb_ifm
);

////////// INSTANCIATION FIFO //////////

logic fifo_read, fifo_write, fifo_rempty,fifo_walmost_full, fifo_wfull;
logic [31:0] fifo_rdata, fifo_wdata;

async_fifo #( .DATA_WIDTH(32), .DEPTH_WIDTH(8), .ALMOST_FULL_THRESHOLD(255) ) sdram_video_fifo (
			.rst(wshb_ifm.rst),
			.rclk(video_ifm.CLK),
			.read(fifo_read),
			.rdata(fifo_rdata),
			.rempty(fifo_rempty),
			.wclk(wshb_ifm.clk),
			.wdata(fifo_wdata),
			.write(fifo_write),
			.wfull(fifo_wfull),
			.walmost_full(fifo_walmost_full)
);


////////// GENERATION DES SIGNAUX //////////

localparam HFP=40;
localparam HPULSE=48;
localparam HBP=40;
localparam VFP=13;
localparam VPULSE=3;
localparam VBP = 29;
localparam HCNT_SIZE = HFP+HPULSE+HBP+HDISP;
localparam VCNT_SIZE = VFP+VPULSE+VBP+VDISP;

////////// GESTION DES COMPTEURS VGA //////////

localparam HCNT_WIDTH = $clog2(HCNT_SIZE);
localparam VCNT_WIDTH = $clog2(VCNT_SIZE);

logic[HCNT_WIDTH-1:0] h_cnt;
logic[VCNT_WIDTH-1:0] v_cnt;

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

////////// GENERATION DES SIGNAUX DE CONTROLE VGA //////////

assign video_ifm.CLK = pixel_clk;
assign video_ifm.HS = !(h_cnt >= HFP && h_cnt < HFP+HPULSE);
assign video_ifm.VS = !(v_cnt >= VFP && v_cnt < VFP+VPULSE);
assign video_ifm.BLANK = (h_cnt >= HFP+HPULSE+HBP) && (v_cnt >= VFP+VPULSE+VBP);


//** LECTURE EN SDRAM ET ECRITURE EN FIFO **//

localparam XCNT_WIDTH = $clog2(HDISP);
localparam YCNT_WIDTH = $clog2(VDISP);

logic[XCNT_WIDTH-1:0] x_cnt_sdram;
logic[YCNT_WIDTH-1:0] y_cnt_sdram;

// Compteurs de lecture
always_ff @ (posedge wshb_ifm.clk)
if(wshb_ifm.rst)
begin
	x_cnt_sdram <= 0;
	y_cnt_sdram <= 0;
end
else
begin
	if(wshb_ifm.ack)
	begin
		// Mise à jour des compteurs
		x_cnt_sdram <= x_cnt_sdram+1;
		if(x_cnt_sdram == HDISP-1)
		begin
			x_cnt_sdram <= 0;
			y_cnt_sdram <= (y_cnt_sdram == VDISP-1) ? 0 : y_cnt_sdram+1;
		end

	end
end

// Passage synchrone du cyc
always_ff @(posedge wshb_ifm.clk)
if(wshb_ifm.rst)
	wshb_ifm.cyc <= '0;
else
begin
	if (wshb_ifm.cyc) wshb_ifm.cyc <= !fifo_wfull;
	else wshb_ifm.cyc <= !fifo_walmost_full;
end


// Génération des signaux de lecture
assign wshb_ifm.stb = !fifo_wfull;
assign wshb_ifm.adr = (x_cnt_sdram + y_cnt_sdram*HDISP)*4;
assign wshb_ifm.we = 1'b0;
assign wshb_ifm.sel = 4'b1111;
assign wshb_ifm.cti = '0;
assign wshb_ifm.bte = '0;
assign wshb_ifm.dat_ms = '0;

// Ecriture FIFO
assign fifo_write = wshb_ifm.ack;
assign fifo_wdata = wshb_ifm.dat_sm;



////////// LECTURE EN FIFO //////////s


// Adaptation du signal first full dans le bon système d'horloge
logic pre_first_full, video_began;

always_ff @ (video_ifm.CLK)
if(pixel_rst)
begin
	pre_first_full <= 1'b0;
	video_began <= 1'b0;
end
else
	if(!video_ifm.VS)
	begin
		// On attends que la fifo soit full
		pre_first_full <= fifo_wfull;

		// Puis, dès qu'on est entre 2 frames, on commence
		video_began <= pre_first_full;
	end

assign fifo_read = video_ifm.BLANK & video_began;

////////// ENVOI PIXEL //////////

assign video_ifm.RGB = fifo_rdata;


endmodule
