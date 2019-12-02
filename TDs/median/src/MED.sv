module MED #(parameter SIZE = 8, parameter LENGHT = 9) (input logic [SIZE-1:0] DI,
  input logic DSI,
  input logic BYP,
  input logic CLK,
  output logic [SIZE-1:0] DO
  );

  logic [SIZE-1:0] Regs [LENGHT-1:0];
  logic [SIZE-1:0] MCE_min, MCE_max;

  // Regs[SIZE-1] représente la valeur que l'on va comparer succesivement avec les autres
  // Avec BYP = 1 on place une nouvelle valeur dans celui ci sans comparaison
  // Avec BYP = 0 on y place à chaque fois le max et l'ancienne valeur retourne dans le registre à décalage
  // Après LENGHT-1 coups d'horloges à BYP = 0 on est sur d'avoir la plus grande valeur dans Regs[SIZE-1]
  // On la supprime et on répète LENGHT / 2 fois
  // Comme elle n'est pas réellement "supprimée" mais écrasée on doit augmentter la durée de  BYP a chaque fois
  always_ff @(posedge CLK)
  begin
    Regs[0] <= DSI ? DI : MCE_min;

    // Partie registre à décalage
    for(int k = 1; k <= LENGHT-2 ; k++)
      Regs[k] <= Regs[k-1];

    Regs[LENGHT-1] <= BYP ? Regs[LENGHT-2] : MCE_max;
  end

  assign DO = Regs[LENGHT-1];


  MCE I_MCE(.A(Regs[LENGHT-1]), .B(Regs[LENGHT-2]), .MAX(MCE_max), .MIN(MCE_min));

endmodule
