module wshb_intercon #(parameter HDISP = 800, parameter VDISP = 480) (
	wshb_if.slave  wshb_ifs_vga,
  wshb_if.slave  wshb_ifs_mire,
  wshb_if.master  wshb_ifm_sdram
);

// Gestion du token
logic token; // 0 = mire, 1 = vga

always_ff @ (posedge wshb_ifm_sdram.clk)
if(wshb_ifm_sdram.rst)
  token <= 0;
else
  token <= token ? wshb_ifs_vga.cyc : !wshb_ifs_mire.cyc;

// Connexions
assign wshb_ifm_sdram.adr = token ? wshb_ifs_vga.adr : wshb_ifs_mire.adr;
assign wshb_ifm_sdram.we = token ? wshb_ifs_vga.we : wshb_ifs_mire.we;
assign wshb_ifm_sdram.cyc = token ? wshb_ifs_vga.cyc : wshb_ifs_mire.cyc;
assign wshb_ifm_sdram.sel = token ? wshb_ifs_vga.sel : wshb_ifs_mire.sel;
assign wshb_ifm_sdram.stb = token ? wshb_ifs_vga.stb : wshb_ifs_mire.stb;
assign wshb_ifm_sdram.cti = token ? wshb_ifs_vga.cti : wshb_ifs_mire.cti;
assign wshb_ifm_sdram.bte = token ? wshb_ifs_vga.bte : wshb_ifs_mire.bte;
assign wshb_ifm_sdram.dat_ms = token ? wshb_ifs_vga.dat_ms : wshb_ifs_mire.dat_ms;

assign wshb_ifs_vga.ack = token ? wshb_ifm_sdram.ack : '0;
assign wshb_ifs_mire.ack = token ? '0 : wshb_ifm_sdram.ack;
assign wshb_ifs_vga.dat_sm = wshb_ifm_sdram.dat_sm;
assign wshb_ifs_mire.dat_sm = wshb_ifm_sdram.dat_sm;
assign wshb_ifs_vga.rty = wshb_ifm_sdram.rty;
assign wshb_ifs_mire.rty = wshb_ifm_sdram.rty;
assign wshb_ifs_vga.err = wshb_ifm_sdram.err;
assign wshb_ifs_mire.err = wshb_ifm_sdram.err;


endmodule
