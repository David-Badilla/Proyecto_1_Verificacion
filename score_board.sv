class score_board #(parameter ancho = 16,parameter drvrs=4);
    trans_sb_mbx chkr_sb_mbx;
    solicitud_sb_mbx test_sb_mbx;
    trans_sb #(.ancho(ancho)) trans_entrante;
    trans_sb scoreboard[$]; //array para controlar el scoreboard
    trans_sb scoreboard_aux[$];
    trans_sb aux_trans;
    shortreal retardo_promedio;    // Esto hay que analizar los paquetes.
    solicitud_sb orden;
    int tamano_sb;
    int trans_completas=0;
    int retardo_total=0;   // analizar lo de los paquetes.
    

	integer f,i;

    task run;
        $display("(%g) El ScoreBoard fue inicializado",$time);
        forever begin
			#5 
			if(chkr_sb_mbx.num()>0)begin
				chkr_sb_mbx.get(trans_entrante);
				trans_entrante.print("Score Board: transaccion recibida del checker");
				if (trans_entrante.completado)begin
					retardo_total = retardo_total + trans_entrante.latencia;
					trans_completas+=1;
				end
				scoreboard.push_back(trans_entrante);
			end else begin
				if(test_sb_mbx.num()>0)begin
					test_sb_mbx.get(orden);
					case (orden)
						retraso_promedio:begin
							//Retraso promedio en la entrega de paquetes x terminal y general en función de la cantidad de dispositivos y las profundidad de las FIFOs.
							$display("Score board: Recibida orden retardo promedio");
							retardo_promedio=retardo_total / trans_completas;
							$display("[%g] Score board: El retardo promedio es: %0.3f",$time,retardo_promedio);
									
						end


						bwmax:begin
			
						end
						bwmin:begin

						end						


						reporte_completo:begin //Debe ser capaz de entregar un reporte de los paquetes enviados recibidos en formato csv. Se debe incluir tiempo de envío terminal de procedencia, terminal de destino tiempo de recibido, retraso en el envío.
							$display("Score board: Recibida orden Reporte completo");
							tamano_sb=this.scoreboard.size();
							f = $fopen("output.csv", "w");
							$fwrite(f, "t_envio, procedencia, destino ,t_recibido, retraso, dato \n");
							for (int i=0;i<tamano_sb;i++)begin
								aux_trans=scoreboard.pop_front;
								//aux_trans.print("SB_reporte:");
								$fwrite(f, "%d, %d, %d, %d, %d, %d \n", 
									aux_trans.tiempo_envio, 
									aux_trans.procedencia, 
									aux_trans.Destino,
									aux_trans.tiempo_recibido,
									aux_trans.retardo,
									aux_trans.dato_enviado);

								scoreboard_aux.push_back(aux_trans);
							end
							scoreboard=scoreboard_aux;
						end


					endcase
				end
			end			
        end
    endtask
    
endclass
