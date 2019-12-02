module MEDIAN #(parameter SIZE = 8) (input logic [SIZE-1:0] DI,
  input logic DSI,
  input logic nRST,
  input logic CLK,
  output logic [SIZE-1:0] DO,
  output logic DSO
  );

  localparam I_WIDTH = $clog2(SIZE);

  logic [I_WIDTH-1:0] count;

  always_ff @(posedge CLK)
  begin
    count++;
  end

endmodule
