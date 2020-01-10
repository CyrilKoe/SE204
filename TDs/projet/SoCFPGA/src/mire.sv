module mire #(parameter HDISP = 800, parameter VDISP = 480) (
	wshb_if.master  wshb_ifm
);

localparam XCNT_WIDTH = $clog2(HDISP);
localparam YCNT_WIDTH = $clog2(VDISP);
logic[XCNT_WIDTH-1:0] x_cnt;
logic[YCNT_WIDTH-1:0] y_cnt;
logic[5:0] breaker;

always_ff @ (posedge wshb_ifm.clk)
if(wshb_ifm.rst)
begin
	x_cnt <= 0;
	y_cnt <= 0;
  breaker <= 0;
end
else
begin
  breaker <= breaker+1;
	if(wshb_ifm.ack)
	begin
		// Mise à jour des compteurs
		x_cnt <= x_cnt+1;
		if(x_cnt == HDISP-1)
		begin
			x_cnt <= 0;
			y_cnt <= (y_cnt == VDISP-1) ? 0 : y_cnt+1;
		end
	end
end

assign wshb_ifm.adr = (x_cnt + y_cnt*HDISP)*4;
assign wshb_ifm.we = 1'b1;
assign wshb_ifm.cyc = wshb_ifm.stb;
assign wshb_ifm.sel = 4'b1111;
assign wshb_ifm.stb = (breaker != 0);
assign wshb_ifm.cti = '0;
assign wshb_ifm.bte = '0;
assign wshb_ifm.dat_ms = ((x_cnt[3:0] == 0) || (y_cnt[3:0] == 0)) ? {8'(x_cnt+y_cnt),(7'(x_cnt+y_cnt))<<1,~(8'(x_cnt+y_cnt))} : 0;

endmodule
