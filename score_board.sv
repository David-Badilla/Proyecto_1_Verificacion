class score_board #(parameter ancho = 16,parameter drvrs=5);
    trans_sb_mbx chkr_sb_mbx;
    solicitud_sb_mbx test_sb_mbx;
    trans_sb #(.ancho(ancho)) trans_entrante;
    trans_sb #(.ancho(ancho)) scoreboard[$]; //array para controlar el scoreboard
    trans_sb #(.ancho(ancho)) scoreboard_aux[$];
    trans_sb #(.ancho(ancho)) aux_trans;
    shortreal retardo_promedio[drvrs-1:0];    // Esto hay que analizar los paquetes.
    solicitud_sb orden;
    int tamano_sb;
    int trans_completas[drvrs-1:0];
    int retardo_total[drvrs-1:0];   // analizar lo de los paquetes.
    int max_t_recibido;


	int bwm[drvrs-1:0][$];
	int temp[drvrs-1:0];
	int t_recibido;
	int relojini;
	int relojfin;
	integer f,i;
	int max;

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
							$display("Score board: Recibida orden retardo promedio");
							for(int i=0;i<drvrs;i++	)begin				
								retardo_promedio[i]=retardo_total[i] / trans_completas[i];
								$display("[%g] Score board: El retardo promedio en dispositivo[%g] es: %0.3f",$time,i,retardo_promedio[i]);	
							end
						end


						bwmax:begin
							relojini=0;
							tamano_sb=this.scoreboard.size();
							max_t_recibido=0;
							for(int u=0;u<drvrs;u++) temp[u]=0; //reinicio de variable temporal
							for(int m=0;m<tamano_sb;m++)begin
								if (scoreboard[m].tiempo_recibido>max_t_recibido)begin								
									max_t_recibido=scoreboard[m].tiempo_recibido;
								end
							end
							$display("		T_max de envio: %g",max_t_recibido);
							for (int i=0;i<=max_t_recibido;i++)begin
								relojfin=relojini+10;	//Crea una ventana de 10 con respecto al reloj inicial para comparar						$
								for(int j=0; j<tamano_sb;j++)begin // recorre toda la cola que almacena los paquetes que fueron ejecutados
									t_recibido=scoreboard[j].tiempo_recibido;
									
									if(t_recibido>=relojini && t_recibido<=relojfin )begin //Revisa si el tiempo recibido se encuentra en esa ventana de ciclo de reloj
										temp[scoreboard[j].Fuente]=temp[scoreboard[j].Fuente]+1;//suma una constante dependiendo de cual fue su fuente		
										$display("T_ini: %g , T fin: %g",relojini,relojfin);
										//$display("			Temp[%g] = %g",j,temp[scoreboard[j].Fuente]);
									end	
								end
								for(int n=0;n<drvrs;n++) begin //Recorre todos los dispositivos
									if(temp[n]!=0) begin
										bwm[n].push_back(temp[n]); //Guarda los tiempos totales de cada ciclo 
										$display(  "Pushed disp[%g]: %g",n, temp[n]);
									end
								end
								for(int u=0;u<drvrs;u++) temp[u]=0;
								relojini=relojfin; //Se reinician las variables para simular el siguiente ciclo de reloj
							end

							for(int n=0;n<drvrs;n++) begin //una vez terminados todos los ciclos se busca cual fue el mayor						
								max=0;
								for(int m=0;m<bwm[n].size();m++) begin
										if(bwm[n][m]>max) max=bwm[n][m]; 
								end
								$display("BWmax del dispositivo [%g] es: %g por ciclo de reloj",n,max);
														
							end	
									
							for(int m=0;m<tamano_sb;m++)begin
								if (scoreboard[m].tiempo_recibido>max_t_recibido)begin								
									max_t_recibido=scoreboard[m].tiempo_recibido;
								end
							end
							
						end
						bwmin:begin

						end						


						reporte_completo:begin //Debe ser capaz de entregar un reporte de los paquetes enviados recibidos en formato csv. Se debe incluir tiempo de envío terminal de procedencia, terminal de destino tiempo de recibido, retraso en el envío.
							$display("Score board: Recibida orden Reporte completo");
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
