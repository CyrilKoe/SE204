module MCE #(parameter SIZE = 8) (input logic [SIZE-1:0] A,
  input logic [SIZE-1:0] B,
  output logic [SIZE-1:0] MAX,
  output logic[SIZE-1:0] MIN
  );

  logic cond;

  assign cond = (A > B);
  assign MAX =  cond ? A : B;
  assign MIN = cond ? B : A;

endmodule
