module MEDIAN #(parameter SIZE = 8, parameter LENGHT = 9) (input logic [SIZE-1:0] DI,
  input logic DSI,
  input logic nRST,
  input logic CLK,
  output logic [SIZE-1:0] DO,
  output logic DSO
  );

  localparam I_WIDTH = $clog2(LENGHT);

  logic BYP;
  logic [I_WIDTH-1:0] count, state;
  logic oldDSI;


  always_ff @(posedge CLK)
  if(!nRST)
  begin
    count <= 0;
    state <= 0;
  end
  else
  begin
    oldDSI <= DSI;
    if(oldDSI != DSI)
    begin
      count = 0;
      state = 0;
      DSO = 0;
    end
    if(!DSI)
    begin
      count = count + 1;
      state <= (count == LENGHT) ? state+1 : state;
      count <= (count == LENGHT) ? 0 : count;
      if(state == 4 && count == 4)
      begin
        count <= 0;
        state <= 0;
        DSO <= 1;
      end
    end
  end

  assign BYP = (count >= LENGHT - 1 - state) | DSI;

  MED I_MED(.DI(DI), .DSI(DSI), .BYP(BYP), .CLK(CLK), .DO(DO));

endmodule
