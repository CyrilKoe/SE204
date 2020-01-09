`timescale 1ns/1ps

`default_nettype none

module tb_Top;

// Entrées sorties extérieures
bit   FPGA_CLK1_50;
logic [1:0]	KEY;
wire  [7:0]	LED;
logic [3:0]	SW;

// Interface vers le support matériel
hws_if      hws_ifm();

// Interface pour la video
video_if    video_if0();

// Instance du module Top
Top #( .HDISP(800), .VDISP(480)) Top0(
  .FPGA_CLK1_50(FPGA_CLK1_50),
  .KEY(KEY),
  .LED(LED),
  .SW(SW),
  .hws_ifm(hws_ifm.master),
  .video_ifm(video_if0.master)
);

 screen #(.mode(13),.X(800),.Y(480)) screen0(.video_ifs(video_if0));

///////////////////////////////
//  Code élèves
//////////////////////////////

always #10ns FPGA_CLK1_50 = ~FPGA_CLK1_50; // On genere une horloge

initial begin: ENTREES
  $dumpfile("../signals.vcd");
  $dumpvars(0,Top0.video_ifm, Top0.wshb_if_sdram, Top0.hw_support_inst);
  KEY[0] = 0;
  #128ns
  KEY[0] = 1;
end

initial begin: TIMER
  #10000ns;
  $stop();
end

endmodule
