`include "seq_pav.sv"
`include "seq_porta.sv"

module tb_controle;
  // Definindo os sinais como reg e wire
  logic RESET, CLOCK;
  logic BI1, BI2, BI3, BI4, BI5;
  logic BE1UP, BE2UP, BE3UP, BE4UP;
  logic BE5DOWN, BE2DOWN, BE3DOWN, BE4DOWN;
  wire  SPA1, SPA2, SPA3, SPA4, SPA5, SPAI;
  wire  SPF1, SPF2, SPF3, SPF4, SPF5, SPFI;
  wire  SA1, SA2, SA3, SA4, SA5;
  logic OPENDOOR, CLOSEDOOR;
  logic NON_STOP;
  logic POTENCIA;
  wire [1:0] MOTOR;
  wire [1:0] PORT1, PORT2, PORT3, PORT4, PORT5, PORT_INTERNA;
  wire ALERTA;
  wire [3:0] DISPLAY;
  
  //Instancia do modulo controle.

controle duv (
    .reset(RESET), .clock(CLOCK), 
    .bi1(BI1), .bi2(BI2), .bi3(BI3), .bi4(BI4), .bi5(BI5),
    .be1UP(BE1UP), .be2UP(BE2UP), .be3UP(BE3UP), .be4UP(BE4UP),
	.be2Down(BE2DOWN), .be3Down(BE3DOWN), .be4Down(BE4DOWN),  
    .be5Down(BE5DOWN),
  .sPa1(SPA1), .sPa2(SPA2), .sPa3(SPA3), .sPa4(SPA4), .sPa5(SPA5), .sPaI(SPAI),
  .sPf1(SPF1), .sPf2(SPF2), .sPf3(SPF3), .sPf4(SPF4), .sPf5(SPF5), .sPfI(SPFI),
    .sA1(SA1), .sA2(SA2), .sA3(SA3), .sA4(SA4), .sA5(SA5),
    .openDoor(OPENDOOR), .closeDoor(CLOSEDOOR),
  	.non_stop(NON_STOP),
    .potencia(POTENCIA), 
    .motor(MOTOR),
    .port1(PORT1), .port2(PORT2), .port3(PORT3), .port4(PORT4), .port5(PORT5), .port_interna(PORT_INTERNA),
    .alerta(ALERTA),
    .display(DISPLAY)
);
  
  
seq_pavimento my_seq_pavimento (
  .clk(CLOCK), 
  .rst(RESET),
  .motor(MOTOR),
  .s1(SA1), 
  .s2(SA2), 
  .s3(SA3), 
  .s4(SA4), 
  .s5(SA5)
);
  
time_trans_port my_ttp1 (
  .clk(CLOCK), 
  .rst(RESET),
  .motorPorta(PORT1),
  .spa(SPA1), 
  .spf(SPF1)
);
  
time_trans_port my_ttp2 (
  .clk(CLOCK), 
  .rst(RESET),
  .motorPorta(PORT2),
  .spa(SPA2), 
  .spf(SPF2)
);
  
time_trans_port my_ttp3 (
  .clk(CLOCK), 
  .rst(RESET),
  .motorPorta(PORT3),
  .spa(SPA3), 
  .spf(SPF3)
);
  
time_trans_port my_ttp4 (
  .clk(CLOCK), 
  .rst(RESET),
  .motorPorta(PORT4),
  .spa(SPA4), 
  .spf(SPF4)
);
  
time_trans_port my_ttp5 (
  .clk(CLOCK), 
  .rst(RESET),
  .motorPorta(PORT5),
  .spa(SPA5), 
  .spf(SPF5)
);

time_trans_port my_ttp_i (
  .clk(CLOCK), 
  .rst(RESET),
  .motorPorta(PORT_INTERNA),
  .spa(SPAI), 
  .spf(SPFI)
);
  
/*

 tempo de duração do click do botão = 2ns
 tempo de porta totalmente aberta = 50 pclock -> 100ns 
 tempo de transição de porta aberta para fechada = 20 pclock -> 40ns 
 tempo de transição de porta fechada para aberta = 20 pclock -> 40ns 
 tempo de transição de andar = 20pclock -> 40ns

*/

always #1 CLOCK = ~CLOCK; //gera sinal de clock com periodo de 4 ns


initial begin
  $dumpfile("tb.vcd");
  $dumpvars(0,tb_controle);

  //inicializa os sinais
  //clock e reset.
  RESET = 1;
  CLOCK = 0;
  // Botões internos - todos desligados
  BI1 = 0;
  BI2 = 0;
  BI3 = 0;
  BI4 = 0;
  BI5 = 0;
  // Botões externos para subir - todos desligados
  BE1UP = 0;
  BE2UP = 0;
  BE3UP = 0;
  BE4UP = 0;
  // Botões externos para descer - todos desligados
  BE2DOWN = 0;
  BE3DOWN = 0;
  BE4DOWN = 0;
  BE5DOWN = 0;

  // Botões para abertura e fechamento da porta
  OPENDOOR = 0;
  CLOSEDOOR = 0;
  // Função Non-Stop desativada
  NON_STOP = 0;
  // Potência ativa
  POTENCIA = 1;

  #14 RESET = 0; //INICIO DO SISTEMA
  // primeiro cenario, subida simples até o quinto andar.
  

  // Teste de subida para 5 andar
  
  //Pedro clica em Be1up solicitando subida.
  BI1 = 0; BI2 = 0; BI3 = 0; BI4 = 0; BI5 = 0; //botoes internos
  BE1UP = 1; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 0; //botoẽs externos descida
  #4 //solta botão. 
  BI1 = 0; BI2 = 0; BI3 = 0; BI4 = 0; BI5 = 0; //botoes internos
  BE1UP = 0; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 0; //botoẽs externos descida

  #200 // Tempo para gerar novo click, no caso bi5

  BI1 = 0; BI2 = 0; BI3 = 0; BI4 = 0; BI5 = 1; //botoes internos
  BE1UP = 0; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 0; //botoẽs externos descida
  #4 //tempo de duração do click em bi5
  BI1 = 0; BI2 = 0; BI3 = 0; BI4 = 0; BI5 = 0; //botoes internos
  BE1UP = 0; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 0; //botoẽs externos descida

  #500 // Tempo de transição para subir ou descer


  // Teste de descida para 3 andar
  
  //João clica em Be5down solicitando descida.
  BI1 = 0; BI2 = 0; BI3 = 0; BI4 = 0; BI5 = 0; //botoes internos
  BE1UP = 0; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 1; //botoẽs externos descida
  #4 //solta botão. 
  BI1 = 0; BI2 = 0; BI3 = 0; BI4 = 0; BI5 = 0; //botoes internos
  BE1UP = 0; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 0; //botoẽs externos descida

  #200 // Tempo para gerar novo click, no caso bi3

  BI1 = 0; BI2 = 0; BI3 = 1; BI4 = 0; BI5 = 0; //botoes internos
  BE1UP = 0; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 0; //botoẽs externos descida
  #4 //tempo de duração do click em bi5
  BI1 = 0; BI2 = 0; BI3 = 0; BI4 = 0; BI5 = 0; //botoes internos
  BE1UP = 0; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 0; //botoẽs externos descida

  #500 // Tempo de transição para subir ou descer  
  

    // Teste de descida chamada externa gerada do 1 andar
  
  //Zé clica em Be1up solicitando uma subida.
  BI1 = 0; BI2 = 0; BI3 = 0; BI4 = 0; BI5 = 0; //botoes internos
  BE1UP = 1; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 0; //botoẽs externos descida
  #4 //solta botão. 
  BI1 = 0; BI2 = 0; BI3 = 0; BI4 = 0; BI5 = 0; //botoes internos
  BE1UP = 0; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 0; //botoẽs externos descida

  #200 // Tempo para gerar novo click, no caso bi4

  BI1 = 0; BI2 = 0; BI3 = 1; BI4 = 1; BI5 = 0; //botoes internos
  BE1UP = 0; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 0; //botoẽs externos descida
  #4 //tempo de duração do click em bi5
  BI1 = 0; BI2 = 0; BI3 = 0; BI4 = 0; BI5 = 0; //botoes internos
  BE1UP = 0; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 0; //botoẽs externos descida

  #500 // Tempo de transição para subir ou descer  

  
  // Criem novos testes
  
  BI1 = 0; BI2 = 1; BI3 = 0; BI4 = 0; BI5 = 0; //botoes internos
  BE1UP = 0; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 0; //botoẽs externos descida
  #4
  BI1 = 0; BI2 = 0; BI3 = 0; BI4 = 0; BI5 = 0; //botoes internos
  BE1UP = 0; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 0; //botoẽs externos descida
  
  #94
  BI1 = 0; BI2 = 0; BI3 = 1; BI4 = 0; BI5 = 0; //botoes internos
  BE1UP = 0; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 0; //botoẽs externos descida
	#4
  BI1 = 0; BI2 = 0; BI3 = 0; BI4 = 0; BI5 = 0; //botoes internos
  BE1UP = 0; BE2UP = 0; BE3UP = 0; BE4UP = 0; //botoẽs externos subida
  BE2DOWN = 0; BE3DOWN = 0; BE4DOWN = 0; BE5DOWN = 0; //botoẽs externos descida
  
  #700;
  #100 $finish();
  //*************************************** Outros testes foram feitos, mas eu só fui fazendo e apagando pra não ficar com o epwave mto longo.
  
  
  
  
  
end





endmodule;