module wshb_intercon #(parameter HDISP = 800, parameter VDISP = 480) (
	output logic token,
	wshb_if.slave  wshb_ifs_vga,
  wshb_if.slave  wshb_ifs_mire,
  wshb_if.master  wshb_ifm_sdram
);

// Gestion du token
// 0 = mire, 1 = vga

always_ff @ (posedge wshb_ifm_sdram.clk)
if(wshb_ifm_sdram.rst)
  token <= 0;
else
begin
  if(token & !wshb_ifs_vga.cyc) token <= !token;
	if(!token & !wshb_ifs_mire.cyc) token <= !token;
end

// Signaux ESCLAVE -> MAITRE
always_comb begin
	if(token)
	begin
		wshb_ifm_sdram.adr = wshb_ifs_vga.adr;
		wshb_ifm_sdram.we = wshb_ifs_vga.we;
		wshb_ifm_sdram.cyc = wshb_ifs_vga.cyc;
		wshb_ifm_sdram.sel = wshb_ifs_vga.sel;
		wshb_ifm_sdram.stb = wshb_ifs_vga.stb;
		wshb_ifm_sdram.cti = wshb_ifs_vga.cti;
		wshb_ifm_sdram.bte = wshb_ifs_vga.bte;
		wshb_ifm_sdram.dat_ms = wshb_ifs_vga.dat_ms;
	end
	else
	begin
		wshb_ifm_sdram.adr = wshb_ifs_mire.adr;
		wshb_ifm_sdram.we = wshb_ifs_mire.we;
		wshb_ifm_sdram.cyc = wshb_ifs_mire.cyc;
		wshb_ifm_sdram.sel = wshb_ifs_mire.sel;
		wshb_ifm_sdram.stb = wshb_ifs_mire.stb;
		wshb_ifm_sdram.cti = wshb_ifs_mire.cti;
		wshb_ifm_sdram.bte = wshb_ifs_mire.bte;
		wshb_ifm_sdram.dat_ms = wshb_ifs_mire.dat_ms;
	end
end

// Signaux MAITRE -> ESCLAVE
always_comb begin
	if(token)
	begin
		wshb_ifs_vga.ack = wshb_ifm_sdram.ack;
		wshb_ifs_mire.ack = '0;
		wshb_ifs_vga.dat_sm = wshb_ifm_sdram.dat_sm;
		wshb_ifs_mire.dat_sm = '0;
		wshb_ifs_vga.rty = wshb_ifm_sdram.rty;
		wshb_ifs_mire.rty = '0;
		wshb_ifs_vga.err = wshb_ifm_sdram.err;
		wshb_ifs_mire.err = '0;
	end
	else
	begin
		wshb_ifs_vga.ack = '0;
		wshb_ifs_mire.ack = wshb_ifm_sdram.ack;
		wshb_ifs_vga.dat_sm = '0;
		wshb_ifs_mire.dat_sm = wshb_ifm_sdram.dat_sm;
		wshb_ifs_vga.rty = '0;
		wshb_ifs_mire.rty = wshb_ifm_sdram.rty;
		wshb_ifs_vga.err = '0;
		wshb_ifs_mire.err = wshb_ifm_sdram.err;
	end
end

endmodule
