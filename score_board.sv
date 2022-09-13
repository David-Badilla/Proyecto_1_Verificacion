class score_board #(parameter ancho = 16);
    trans_sb_mbx chkr_sb_mbx;
    solicitud_sb_mbx test_sb_mbx;
    trans_sb #(.ancho(ancho)) trans_entrante;
    trans_sb scoreboard[$]; //array para controlar el scoreboard
    trans_sb scoreboard_aux[$];
    trans_sb aux_trans;
    //shortreal retardo_promedio      Esto hay que analizar los paquetes.
    solicitud_sb_mbx orden;
    int tamano_sb;
    int trans_completas;
    //int retardo_total;    analizar lo de los paquetes.
    
    task run;
        $display("(%g) El ScoreBoard fue inicializado",$time);
        forever begin
            
        end
    endtask
    
endclass
