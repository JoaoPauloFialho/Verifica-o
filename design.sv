module controle(
	input logic reset, clock, 
    input logic bi1, bi2, bi3, bi4, bi5,
    input logic be1UP, be2UP, be3UP, be4UP,
    input logic be2Down, be3Down, be4Down, be5Down,
    input logic sPa1, sPa2, sPa3, sPa4, sPa5, sPaI,
    input logic sPf1, sPf2, sPf3, sPf4, sPf5, sPfI,
    input logic sA1, sA2, sA3, sA4, sA5,
    input logic openDoor, closeDoor,
    input logic non_stop,
    input logic potencia, 
    output logic [1:0] motor,
    output logic [1:0] port1, port2, port3, port4, port5, port_interna,
    output logic alerta,
  	output logic [3:0] display
);

    parameter TEMPODEPORTA = 50;

    /*DEFINIÇÃO DE STRUCTS*/

    typedef enum logic [1:0] { 
        SUBINDO = 2'b01,
        DESCENDO = 2'b10,
        PARADO = 2'b00
    } sentido_motor_t;

    typedef enum logic [3:0] { 
        ANDAR1,
        ENTRE_1_2,
        ANDAR2,
        ENTRE_2_3,
        ANDAR3,
        ENTRE_3_4,
        ANDAR4,
        ENTRE_4_5,
        ANDAR5

    } andares_t;

    typedef struct {
        logic ativo; //normalmente  0
        andares_t andar; //andar do botão
        logic atende; // normalmente 1, desativa caso o botão seja ligado durante transição
        sentido_motor_t sentido; //parado caso seja interno
    } botao_t;

    typedef enum logic [2:0] { 
        PARAR_MOTOR,
        ABRINDO_P,
        TEMPO_P,
        FECHANDO_P,
        P_FECHADA
    } sub_maquina_t;

    /*funcoes de codigo*/

    // Função para limpar o campo "ativo" e o campo "atende" de um botão.
    function void limpar_estado_ativo(ref botao_t botao_int);
            botao_int.ativo = 0;
            botao_int.atende = 1;
    endfunction

    function void sub_maquina_func(
        ref logic [1:0] porta,
        ref sub_maquina_t sub_maquina,
        ref logic [1:0] motor,
        ref int contador,
        input logic openDoor,
        logic closeDoor,
        logic sensor_pf,
        logic sensor_pa );

        case (sub_maquina)

            PARAR_MOTOR:begin
                motor = PARADO; //para o motor.
                if(sensor_pf) 
                    sub_maquina = ABRINDO_P; //vai pra abrindo a porta.
            end

            ABRINDO_P:begin
                porta = SUBINDO;
                if(sensor_pa)begin
                    contador = 0;
                    sub_maquina = TEMPO_P;
                end
            end

            TEMPO_P:begin
                porta = PARADO;
                if(contador >= TEMPODEPORTA || closeDoor)begin
                    contador = 0;
                    sub_maquina = FECHANDO_P;
                end
                else if(openDoor) contador = 0;
                else contador ++;
            end

            FECHANDO_P:begin
                porta = DESCENDO;
                if(openDoor)begin
                    sub_maquina = ABRINDO_P;
                end
                else if(sensor_pf)begin
                    sub_maquina = P_FECHADA;
                end
            end
        endcase
    endfunction

    function void sub_maquina_motor (
        ref sentido_motor_t estado,
        ref logic [1:0] saida,
        input botao_t botao_int [5],
        botao_t botoes_ext_up [4],
        botao_t botoes_ext_down [4],
        int andar);

        case (estado)

            SUBINDO:begin
                for (int i = andar; i < 5; ++i) begin
                    if( botao_int[i].ativo || botoes_ext_up[i].ativo || botoes_ext_down[i].ativo)begin
                        saida = SUBINDO;
                        return;
                    end
                end
                estado = PARADO;
                saida = PARADO;
            end


            DESCENDO:begin
                for (int i=0; i < andar; ++i) begin
                    if( botao_int[i].ativo || botoes_ext_up[i].ativo || botoes_ext_down[i].ativo)begin
                        saida = DESCENDO;
                        return;
                    end
                end
                estado = PARADO;
                saida = PARADO;
            end

            PARADO:begin
                for (int i = andar; i < 5 ;++i) begin
                    if( botao_int[i].ativo || botoes_ext_up[i].ativo || botoes_ext_down[i].ativo)begin
                        estado = SUBINDO;
                        return;
                        
                    end
                end

                for (int i=0; i < andar; ++i) begin
                    if( botao_int[i].ativo || botoes_ext_up[i].ativo || botoes_ext_down[i].ativo)begin
                        estado = DESCENDO;
                        return;
                    end
                end

                saida = PARADO;
            end
            
        endcase
    endfunction;

    function void fehca_porta(logic sensor_pf, ref logic [1:0] porta);
        if(!sensor_pf) porta = DESCENDO;
        else porta = PARADO;
        

    endfunction

    /* STRUCT DOS BOTÕES*/

    botao_t botoes_internos[5] = '{
        '{0, ANDAR1, 1 , PARADO},
        '{0, ANDAR2, 1 , PARADO},
        '{0, ANDAR3, 1 , PARADO},
        '{0, ANDAR4, 1 , PARADO},
        '{0, ANDAR5, 1 , PARADO}
    };
    botao_t botoes_externos_up[4] = '{
        '{0, ANDAR1, 1 , SUBINDO},
        '{0, ANDAR2, 1 , SUBINDO},
        '{0, ANDAR3, 1 , SUBINDO},
        '{0, ANDAR4, 1 , SUBINDO}
    };
    botao_t botoes_externos_down[4] = '{
        '{0, ANDAR2, 1 , DESCENDO},
        '{0, ANDAR3, 1 , DESCENDO},
        '{0, ANDAR4, 1 , DESCENDO},
        '{0, ANDAR5, 1 , DESCENDO}
    };


    /*variaveis intermediarias*/

    sentido_motor_t sentido_motor;

    andares_t estado;
    sub_maquina_t sub_maquina;

    int count;
    logic [4:0] sensores_pav;
    assign sensores_pav = {sA5,sA4,sA3,sA2,sA1};

    always @(posedge clock) begin
        if(motor != PARADO)begin
            if( ($countones({sPa1,sPa2,sPa3,sPa4,sPa5,sPaI} != 0)) || ($countones({sPf1,sPf2,sPf3,sPf4,sPf5,sPfI})  < 6 )) begin
                alerta = 1;
                $display("entrou no erro dos sensores %d\n", $countones({sPf1,sPf2,sPf3,sPf4,sPf5,sPfI}));
            end
        end
    end

    always @(posedge clock or posedge reset) begin
        case (sensores_pav)
        5'b00001:begin
            estado = ANDAR1;
        end
        5'b00010:begin
            estado = ANDAR2;
        end
        5'b00100:begin
            estado = ANDAR3;
        end
        5'b01000:begin
            estado = ANDAR4;
        end
        5'b10000:begin
            estado = ANDAR5;
        end

        default: begin
            if($countones(sensores_pav) == 0)begin
                if(estado != ENTRE_1_2 && estado != ENTRE_2_3 && estado != ENTRE_3_4 && estado != ENTRE_4_5)begin
                    if(estado == ANDAR1 && motor == SUBINDO)begin
                        estado = ENTRE_1_2;
                    end
                    else if(estado == ANDAR5 && motor == DESCENDO) begin
                        estado = ENTRE_4_5;
                    end
                    else begin
                        if(motor == SUBINDO)begin                    
                            estado = estado.next();
                        end
                        else estado = estado.prev();
                    end
                end
            end
            else alerta = 1;
        end
          endcase
    end

    always @(posedge clock or posedge reset) begin
        if(reset)begin

            /*declarando rotina de reset como ativa*/
            alerta = 0;
            /*limpando chamadas ativas*/
            foreach (botoes_externos_up[i]) begin
                limpar_estado_ativo(botoes_externos_up[i]);
            end
            foreach (botoes_externos_down[i]) begin
                limpar_estado_ativo(botoes_externos_down[i]);
            end
            foreach (botoes_internos[i]) begin
                limpar_estado_ativo(botoes_internos[i]);
            end
            sentido_motor = PARADO;
            sub_maquina = PARAR_MOTOR;
            port1 = 0;
            port2 = 0;
            port3 = 0;
            port4 = 0;
            port5 = 0;
        end
        else 
        if(!alerta && potencia)begin
            case (estado)
                ANDAR1:begin
                    display = 0;
                    if ( (openDoor && (motor == PARADO)) || (botoes_internos[0].ativo) || (botoes_externos_up[0].ativo) ) begin
                        sub_maquina_func(port1, sub_maquina, motor, count, openDoor, closeDoor, sPf1, sPa1);
                        port_interna = port1;
                        if (sub_maquina == P_FECHADA) begin
                            limpar_estado_ativo(botoes_internos[0]);
                            limpar_estado_ativo(botoes_externos_up[0]);
                            port1 = PARADO;
                            port_interna = PARADO;
                            sub_maquina = PARAR_MOTOR;
                            count = 0;

                        end
                    end
                    else begin
                        sub_maquina_motor(sentido_motor, motor, botoes_internos, botoes_externos_up, botoes_externos_down, 0);
                    end
                end

                ENTRE_1_2:begin
                    if (sentido_motor == DESCENDO) begin
                        botoes_externos_down[0].atende = 1;
                        botoes_externos_up[1].atende = 1;
                        botoes_internos[1].atende = 1;
                    end
                end

                ANDAR2:begin
                    display = 1;
                    if ( (openDoor && (motor == PARADO)) || (botoes_internos[1].ativo && botoes_internos[1].atende) || (botoes_externos_up[1].ativo && botoes_externos_up[1].atende)
                     || (botoes_externos_down[0].ativo && botoes_externos_down[0].atende)  ) begin
                        sub_maquina_func(port2, sub_maquina, motor, count, openDoor, closeDoor, sPf2, sPa2);
                        port_interna = port2;
                        if (sub_maquina == P_FECHADA) begin
                            limpar_estado_ativo(botoes_internos[1]);
                            limpar_estado_ativo(botoes_externos_up[1]);
                            limpar_estado_ativo(botoes_externos_down[0]);
                            port2 = PARADO;
                            port_interna = PARADO;
                            sub_maquina = PARAR_MOTOR;
                            count = 0;

                        end
                    end
                    else begin
                        sub_maquina_motor(sentido_motor, motor, botoes_internos, botoes_externos_up, botoes_externos_down, 1);
                    end
                end

                ENTRE_2_3:begin
                    if(sentido_motor == DESCENDO)begin
                        botoes_externos_down[1].atende = 1;
                        botoes_externos_up[2].atende = 1;
                        botoes_internos[2].atende = 1;
                    end
                    else if(sentido_motor == SUBINDO)begin
                        botoes_externos_down[0].atende = 1;
                        botoes_externos_up[1].atende = 1;
                        botoes_internos[1].atende = 1;
                    end
                end

                ANDAR3:begin
                    display = 2;
                    if ( (openDoor && (motor == PARADO)) || (botoes_internos[2].ativo && botoes_internos[2].atende) || (botoes_externos_up[2].ativo && botoes_externos_up[2].atende)
                     || (botoes_externos_down[1].ativo && botoes_externos_down[1].atende)  ) begin
                        sub_maquina_func(port3, sub_maquina, motor, count, openDoor, closeDoor, sPf3, sPa3);
                        port_interna = port3;
                        if (sub_maquina == P_FECHADA) begin
                            limpar_estado_ativo(botoes_internos[2]);
                            limpar_estado_ativo(botoes_externos_up[2]);
                            limpar_estado_ativo(botoes_externos_down[1]);
                            port3 = PARADO;
                            port_interna = PARADO;
                            sub_maquina = PARAR_MOTOR;
                            count = 0;

                        end
                    end
                    else begin
                        sub_maquina_motor(sentido_motor, motor, botoes_internos, botoes_externos_up, botoes_externos_down, 2);
                    end
                end

                ENTRE_3_4:begin
                    if(sentido_motor == DESCENDO)begin
                        botoes_externos_down[2].atende = 1;
                        botoes_externos_up[3].atende = 1;
                        botoes_internos[3].atende = 1;
                    end
                    else if(sentido_motor == SUBINDO)begin
                        botoes_externos_down[1].atende = 1;
                        botoes_externos_up[2].atende = 1;
                        botoes_internos[2].atende = 1;
                    end
                end

                ANDAR4:begin
                    display = 3;
                    if ( (openDoor && (motor == PARADO)) || (botoes_internos[3].ativo && botoes_internos[3].atende) || (botoes_externos_up[3].ativo && botoes_externos_up[3].atende)
                     || (botoes_externos_down[2].ativo && botoes_externos_down[2].atende)  ) begin
                        sub_maquina_func(port4, sub_maquina, motor, count, openDoor, closeDoor, sPf4, sPa4);
                        port_interna = port4;
                        if (sub_maquina == P_FECHADA) begin
                            limpar_estado_ativo(botoes_internos[3]);
                            limpar_estado_ativo(botoes_externos_up[3]);
                            limpar_estado_ativo(botoes_externos_down[2]);
                            port4 = PARADO;
                            port_interna = PARADO;
                            sub_maquina = PARAR_MOTOR;
                            count = 0;

                        end
                    end
                    else begin
                        sub_maquina_motor(sentido_motor, motor, botoes_internos, botoes_externos_up, botoes_externos_down, 3);
                    end
                end

                ENTRE_4_5:begin
                    if(sentido_motor == SUBINDO)begin
                        botoes_externos_down[2].atende = 1;
                        botoes_externos_up[3].atende = 1;
                        botoes_internos[3].atende = 1;
                    end
                end

                ANDAR5:begin
                    display = 4;
                    if ( (openDoor && (motor == PARADO)) || (botoes_internos[4].ativo) || (botoes_externos_down[3].ativo) ) begin
                        sub_maquina_func(port5, sub_maquina, motor, count, openDoor, closeDoor, sPf5, sPa5);
                        port_interna = port5;
                        if (sub_maquina == P_FECHADA) begin
                            limpar_estado_ativo(botoes_internos[4]);
                            limpar_estado_ativo(botoes_externos_down[3]);
                            port5 = PARADO;
                            port_interna = PARADO;

                            sub_maquina = PARAR_MOTOR;
                            count = 0;

                        end
                    end
                    else begin
                        sub_maquina_motor(sentido_motor, motor, botoes_internos, botoes_externos_up, botoes_externos_down, 4);
                    end
                end


            endcase
        end
        else begin
            display = 8'hA;
            motor = PARADO;
            fehca_porta(sPf1, port1);
            fehca_porta(sPf2, port2);
            fehca_porta(sPf3, port3);
            fehca_porta(sPf4, port4);
            fehca_porta(sPf5, port5);
            fehca_porta(sPfI, port_interna);
            
        end
    end

    always @(posedge bi1 or posedge reset)begin
        if(reset)begin
            botoes_internos[0].ativo = 1;
            botoes_internos[0].atende = 1;
        end
        else begin
            botoes_internos[0].ativo = 1;
            botoes_internos[0].atende = 1;
        end
    end
    always @(posedge bi2 or posedge reset)begin
        if(reset)begin
            botoes_internos[1].ativo = 0;
            botoes_internos[1].atende = 1;
        end
        else begin
            botoes_internos[1].ativo = 1;
            if((estado == ENTRE_1_2 || estado == ENTRE_2_3) || ((estado == ANDAR1 || estado == ANDAR3) && motor != PARADO)) botoes_internos[1].atende = 0;
            else botoes_internos[1].atende = 1;
        end
    end
    always @(posedge bi3 or posedge reset)begin
        if(reset)begin
            botoes_internos[2].ativo = 0;
            botoes_internos[2].atende = 1;
        end
        else begin
            botoes_internos[2].ativo = 1;
            if((estado == ENTRE_2_3 || estado == ENTRE_3_4) || ((estado == ANDAR2 || estado == ANDAR4) && motor != PARADO))  botoes_internos[2].atende = 0;
            else botoes_internos[2].atende = 1;
        end
    end
    always @(posedge bi4 or posedge reset)begin
        if(reset)begin
            botoes_internos[3].ativo = 0;
            botoes_internos[3].atende = 1;
        end
        else begin
            botoes_internos[3].ativo = 1;
            if((estado == ENTRE_3_4 || estado == ENTRE_4_5) || ((estado == ANDAR3 || estado == ANDAR5) && motor != PARADO)) botoes_internos[3].atende = 0;
            else botoes_internos[3].atende = 1;
        end
    end
    always @(posedge bi5 or posedge reset)begin
        if(reset)begin
            botoes_internos[4].ativo = 0;
            botoes_internos[4].atende = 1;
        end
        else begin
            botoes_internos[4].ativo = 1;
            botoes_internos[3].atende = 1;
        end
    end

    always @(posedge be1UP or posedge reset) begin
        if (reset || non_stop) begin
            botoes_externos_up[0].ativo = 0;
        end
        else begin
            botoes_externos_up[0].ativo = 1;
            botoes_externos_up[0].atende = 1;
        end
    end
    always @(posedge be2UP or posedge reset)begin
        if(reset || non_stop)begin
            botoes_externos_up[1].ativo = 0;
            botoes_externos_up[1].atende = 1;
        end
        else begin
            botoes_externos_up[1].ativo = 1;
            if((estado == ENTRE_1_2 || estado == ENTRE_2_3) || ((estado == ANDAR1 || estado == ANDAR3) && motor != PARADO))  botoes_externos_up[1].atende = 0;
            else botoes_externos_up[1].atende = 1;
        end
    end
    always @(posedge be3UP or posedge reset)begin
        if(reset || non_stop)begin
            botoes_externos_up[2].ativo = 0;
            botoes_externos_up[2].atende = 1;
        end
        else begin
            botoes_externos_up[2].ativo = 1;
            if((estado == ENTRE_2_3 || estado == ENTRE_3_4) || ((estado == ANDAR2 || estado == ANDAR4) && motor != PARADO)) botoes_externos_up[2].atende = 0;
            else botoes_externos_up[2].atende = 1;
        end
    end
    always @(posedge be4UP or posedge reset)begin
        if(reset || non_stop)begin
            botoes_externos_up[3].ativo = 0;
            botoes_externos_up[3].atende = 1;
        end
        else begin
            botoes_externos_up[3].ativo = 1;
            if((estado == ENTRE_3_4 || estado == ENTRE_4_5) || ((estado == ANDAR3 || estado == ANDAR5) && motor != PARADO)) botoes_externos_up[3].atende = 0;
            else botoes_externos_up[3].atende = 1;
        end
    end

    always @(posedge be2Down or posedge reset)begin
        if(reset || non_stop)begin
            botoes_externos_down[0].ativo = 0;
            botoes_externos_down[0].atende = 1;
        end
        else begin
            botoes_externos_down[0].ativo = 1;
            if((estado == ENTRE_1_2 || estado == ENTRE_2_3) || ((estado == ANDAR1 || estado == ANDAR3) && motor != PARADO)) botoes_externos_down[0].atende = 0;
            else botoes_externos_down[0].atende = 1;
        end
    end
    always @(posedge be3Down or posedge reset)begin
        if(reset || non_stop)begin
            botoes_externos_down[1].ativo = 0;
            botoes_externos_down[1].atende = 1;
        end
        else begin
            botoes_externos_down[1].ativo = 1;
            if((estado == ENTRE_2_3 || estado == ENTRE_3_4) || ((estado == ANDAR2 || estado == ANDAR4) && motor != PARADO))  botoes_externos_down[1].atende = 0;
            else botoes_externos_down[1].atende = 1;
        end
    end
    always @(posedge be4Down or posedge reset)begin
        if(reset || non_stop)begin
            botoes_externos_down[2].ativo = 0;
            botoes_externos_down[2].atende = 1;
        end
        else begin
            botoes_externos_down[2].ativo = 1;
            if((estado == ENTRE_3_4 || estado == ENTRE_4_5) || ((estado == ANDAR3 || estado == ANDAR5) && motor != PARADO))  botoes_externos_down[2].atende = 0;
            else botoes_externos_down[2].atende = 1;
        end
    end
    always @(posedge be5Down or posedge reset)begin
        if(reset || non_stop)begin
            botoes_externos_down[3].ativo = 0;
            botoes_externos_down[3].atende = 1;
        end
        else begin
            botoes_externos_down[3].ativo = 1;
            botoes_externos_down[3].atende = 1;
        end
    end

endmodule
