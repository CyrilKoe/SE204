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

  /* PARTIE MACHINE A ETATS */

  enum logic { INIT, RECU } state;


  //Gestion des états
  always_ff @(posedge wb_s.clk)
  if (wb_s.rst)
  state <= INIT ;
  else
  case (state)
    INIT: if (wb_s.stb) state <= RECU;
    RECU: state <= INIT;
  endcase

  //Gestion des signaux de sortie
  always_comb begin
    wb_s.rty = 0;
    wb_s.err = 0;
    wb_s.ack = 0;

    if(state == INIT)
    wb_s.ack = wb_s.we;
    if(state == RECU)
    begin
      wb_s.ack = 1;
    end
  end

  /* PARTIE GESTION DE LA MEMOIRE */

  logic[31:0] mem [2**mem_adr_width-1:0];
  logic [mem_adr_width-1:0] adr;
  logic[31:0] mask;

  //Redimensionnement addresse
  assign adr = wb_s.adr[mem_adr_width-1:0] >> 2;

  //Application du masque
  always_comb
  begin
    for(int k = 3; k >= 0 ; k--)
      mask = {mask, {8{wb_s.sel[k]}}};
  end

  //Ecriture et lecture mémoire
  always_ff @(posedge wb_s.clk)
  begin
    if (wb_s.we)
      mem[adr] <= (mem[adr] & ~mask) | (wb_s.dat_ms & mask);
    wb_s.dat_sm <= mem[adr];
  end

endmodule
