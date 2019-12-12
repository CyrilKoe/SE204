//-----------------------------------------------------------------
// Wishbone BlockRAM
//-----------------------------------------------------------------
//
// Le paramètre mem_adr_width doit permettre de déterminer le nombre
// de mots de la mémoire : (2048 pour mem_adr_width=11)

module wb_bram #(parameter mem_adr_width = 11) (
  // Wishbone interface
  wshb_if.slave wb_s
  );

  /* PARTIE GENERATION DU ACK */

  // Compteur pour retarder l'ack
  logic cnt;

  //Gestion du compteur
  always_ff @(posedge wb_s.clk)
  if(wb_s.rst)
    cnt <= 0;
  else
    if(wb_s.stb)
      cnt <= wb_s.we ? 0 : cnt+1;

  //Gestion des signaux de sortie
  always_comb begin
    wb_s.rty = 0;
    wb_s.err = 0;
    if(wb_s.stb)
      wb_s.ack = wb_s.we ? 1 : (cnt == 1);
    else
      wb_s.ack = 0;
  end

  /* PARTIE GESTION DE LA MEMOIRE */

  logic[31:0] mem [2**mem_adr_width-1:0];
  logic [mem_adr_width-1:0] adr;
  logic[31:0] mask;

  //Redimensionnement addresse
  assign adr = wb_s.adr[mem_adr_width-1:0] >> 2;

  //Creation du masque
  always_comb
  begin
    for(int k = 3; k >= 0 ; k--)
      mask = {mask, {8{wb_s.sel[k]}}};
  end

  //Ecriture et lecture mémoire
  always_ff @(posedge wb_s.clk)
  begin
    if (wb_s.we)
      for(int i = 1; i<=4; i++)
        if(wb_s.sel[i-1]) mem[adr][8*i - 1 -: 8] = wb_s.dat_ms[8*i - 1 -: 8];
    wb_s.dat_sm <= mem[adr];
  end

endmodule
