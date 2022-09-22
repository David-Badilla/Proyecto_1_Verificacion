class score_board #(parameter ancho = 16,parameter drvrs=5);
    trans_sb_mbx chkr_sb_mbx;
    solicitud_sb_mbx test_sb_mbx;
    trans_sb trans_entrante;
    trans_sb scoreboard[$]; //array para controlar el scoreboard
    trans_sb scoreboard_aux[$];
    trans_sb aux_trans;
    shortreal retardo_promedio[drvrs-1:0];    // Esto hay que analizar los paquetes.
    solicitud_sb orden;
    int tamano_sb;
    int trans_completas[drvrs-1:0];
    int retardo_total[drvrs-1:0];   // analizar lo de los paquetes.
    int max_latencia;
	int min_latencia;
	integer f,i;
	int max;
	int bw;
    task run;
        $display("(%g) El ScoreBoard fue inicializado",$time);
        forever begin
			#1 
			if(chkr_sb_mbx.num()>0)begin
				chkr_sb_mbx.get(trans_entrante);
				trans_entrante.print("Score Board: transaccion recibida del checker");
				if (trans_entrante.completado)begin
							
					retardo_total[trans_entrante.Destino] = retardo_total[trans_entrante.Destino] + trans_entrante.latencia;
					trans_completas[trans_entrante.Destino]+=1;
				end
				scoreboard.push_back(trans_entrante);
			end else begin
				if(test_sb_mbx.num()>0)begin
					test_sb_mbx.get(orden);
					
					case (orden)
						retraso_promedio:begin
							//Retraso promedio en la entrega de paquetes x terminal y general en función de la cantidad de dispositivos y las profundidad de las FIFOs.
							$display("\nScore board: Recibida orden retardo promedio");
							for(int i=0;i<drvrs;i++	)begin				
								retardo_promedio[i]=retardo_total[i] / trans_completas[i];
								$display("[%g] Score board: El retardo promedio en dispositivo[%g] es: %g nS",$time,i,retardo_promedio[i]);	
							end
						end


						bwmax:begin
							$display("\nScore board: Recibida orden Ancho de banda maximo");
						
							tamano_sb=this.scoreboard.size();
							max_latencia=0;
							for(int m=0;m<tamano_sb;m++)begin
								if (scoreboard[m].latencia>max_latencia)begin							
									max_latencia=scoreboard[m].latencia;
								end
							end
							bw=ancho/(max_latencia*(0.00000001));
							$display(" \n El ancho de banda maximo del bus es: %g bits/segundo \n",bw);
						end
						bwmin:begin
							$display("Score board: Recibida orden Ancho de banda minimo");
							tamano_sb=this.scoreboard.size();
							min_latencia=9999999999999999;
							for(int m=0;m<tamano_sb;m++)begin
								if (scoreboard[m].latencia<min_latencia)begin							
									min_latencia=scoreboard[m].latencia;
								end							
							end
							bw=ancho/(min_latencia*(0.00000001));//Escalado al ser en nanosegundos
							$display(" \n El ancho de banda minimo del bus es: %d bits/segundo \n",bw);

						end						


						reporte_completo:begin //Debe ser capaz de entregar un reporte de los paquetes enviados recibidos en formato csv. Se debe incluir tiempo de envío terminal de procedencia, terminal de destino tiempo de recibido, retraso en el envío.
							$display("\nScore board: Recibida orden Reporte completo");
							tamano_sb=this.scoreboard.size();
							f = $fopen("output.csv", "w");
							$fwrite(f, "T_envio  , Fuente,  Procedencia, Destino ,T_recibido, retraso, dato \n");
							for (int i=0;i<tamano_sb;i++)begin
								aux_trans=scoreboard.pop_front;
								//aux_trans.print("SB_reporte:");
								$fwrite(f, "%d, %d, %d, %d, %d, %d, %d \n", 
									aux_trans.tiempo_envio, 
									aux_trans.Fuente,
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
