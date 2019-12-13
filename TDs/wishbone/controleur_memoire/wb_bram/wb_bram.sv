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
  logic counter, burst_enabled, burst_condition;

  // Condition de lancement du burst, bug si le maître envoie un CTI "reserved"
  // Pas non plus de test du burst lineaire ou non, a priori non demandé
  assign burst_condition = !counter && wb_s.cti[0] ^ wb_s.cti[1];

  //Gestion du compteur et du burst
  always_ff @(posedge wb_s.clk)
  if(wb_s.rst)
  begin
    counter <= 0;
    burst_enabled <= 0;
  end
  else
  begin
    if(wb_s.stb)
    begin
      // On stoppe l'avancement du conteur si il y a un burst
      counter <= wb_s.we ^ burst_enabled ? 0 : counter+1;
      // Lancement du burst (que si lecture)
      if(burst_condition)
        burst_enabled <= !wb_s.we;
      // Si cti = 111 (marche si pas de CTI reserved)
      if(wb_s.cti[2])
        burst_enabled <= 0;
    end
    else
      counter <= 0;
  end

  //Gestion des signaux de sortie
  always_comb begin
    wb_s.rty = 0;
    wb_s.err = 0;
    // Si burst on ack directement
    if(wb_s.stb)
      wb_s.ack = wb_s.we ? 1 : (counter == 1) | burst_enabled;
    else
      wb_s.ack = 0;
  end

  /* PARTIE GESTION DE LA MEMOIRE */

  logic[31:0] mem [2**mem_adr_width-1:0];
  logic [mem_adr_width-1:0] adr;
  logic[31:0] mask;

  //Redimensionnement addresse, en cas de burst on lit directement la prochaine
  assign adr = (burst_enabled) ? (wb_s.adr >> 2 ) + 1 : wb_s.adr >> 2;

  //Ecriture et lecture mémoire, nécessite une mémoire coupée en 4 mais sinon je ne trouve pas comment masquer
  always_ff @(posedge wb_s.clk)
  begin
    if (wb_s.we)
      for(int i = 1; i<=4; i++)
        if(wb_s.sel[i-1]) mem[adr][8*i - 1 -: 8] = wb_s.dat_ms[8*i - 1 -: 8];
          wb_s.dat_sm <= mem[adr];
  end

endmodule
