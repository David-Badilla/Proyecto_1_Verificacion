
class driver #(parameter drvrs = 4, parameter ancho = 16);

	virtual bus_if #(.drvrs(drvrs),.pckg_sz(ancho)) vif;
	trans_dut_mbx agnt_drv_mbx;
	trans_dut_mbx drv_chkr_mbx;
	trans_dut #(.ancho(ancho), .drvrs(drvrs)) subprocesos_entrada[drvrs-1:0][$]; //Cola de tipo trans dut para cada dispositivo
	trans_dut #(.ancho(ancho), .drvrs(drvrs)) subprocesos_salida[drvrs-1:0][$]; //No utilizada 
	
	
	trans_dut #(.ancho(ancho), .drvrs(drvrs)) trans[drvrs-1:0]; //Variables temporales para almacenar cada transaccion de la fifo(queue)
	trans_dut #(.ancho(ancho), .drvrs(drvrs)) Retardoins[drvrs-1:0];
	trans_dut #(.ancho(ancho), .drvrs(drvrs)) recibido[drvrs-1:0];
	
	int espera[drvrs-1:0];
	task run();
		$display("[%g] El driver fue inicializado",$time);
		@(posedge vif.clk);
		vif.rst=1;;
		@(posedge vif.clk);

		for (int i = 0; i < drvrs; i++) begin 
			Retardoins[i]=new;
      		trans[i] = new;
	    end
		//$display ("Driver: se inician los subprocesos");
		
			
		fork 
			begin //Hijo para rebicion de transaccion entrante de mbx
				@(posedge vif.clk);
				forever begin
					trans_dut #(.ancho(ancho), .drvrs(drvrs)) transaccion; //Crea un objeto para almacenar la transaccion siguiente
					$display("[%g] El Driver espera una transaccion",$time);
					//@(posedge vif.clk);
					agnt_drv_mbx.get(transaccion);		//espera a que haya algo en el mailbox bloqueando el avance
					//transaccion.fuente=0;
					//transaccion.destino=0;


					transaccion.print("Driver: Transaccion recibida");	//imprime lo que recibi?? 
					$display("transacciones pendientes en mbx agnt-driver = %g",agnt_drv_mbx.num()); //muestra todas las instrucciones pendientes en el mbx agnt-driver
					
					
					////////////////////////////////////////////////////////////////////////////////////
					/// Division de las instrucciones en diferentes fifos (colas)
					////////////////////////////////////////////////////////////////////////////////////
					
					subprocesos_salida[transaccion.fuente].push_back(transaccion); //coloca la transaccion en la cola(fifo) correspondiente a la fuente
					$display("		Cantidad de datos en la cola disp[%g]: %g",transaccion.fuente,subprocesos_entrada[transaccion.fuente].size());
					@(posedge vif.clk);
					
				end //end del forever		
					
			end //end hijo 1
			
		
						// inicia la generacion de hijos para cada interfaz
			 
			begin //begin hijo 2 dispositivos 
				for (int j=0;j<drvrs;j++)begin  //-----crea los hijos que diga drvrs---------------
					automatic int i=j;
					fork
						/*begin
							forever begin
								@(posedge vif.clk);
								
								$display("					POP? dip[%g]= %g",i,vif.pop[0][i]);
								
							end
						end*/
						begin //hijo Retrasos
							@(posedge vif.clk);
							forever begin
									espera[i]=0;
								if(subprocesos_salida[i].size()>0)begin
									Retardoins[i]=subprocesos_salida[i].pop_front;
									while(espera[i] < Retardoins[i].retardo)begin 	//manejo del retardo 
										
										@(posedge vif.clk);
										espera[i]=espera[i]+1;
										
										if(espera[i]==Retardoins[i].retardo)begin

											Retardoins[i].print("Driver: transaccion dispositivo enviada");
											subprocesos_entrada[i].push_back(Retardoins[i]);
											$display("		Pop en dipositivo %g",i);
										
											//trans[i].tiempo_envio=$time;
											//SE prodria enviar acá trans[i] al checker como un tipo de referencia a la transaccion enviada											
										end else begin
											//trans[i].dato<=0;
											//trans[i].destino<=0;
										end	
									end //end while
								end
								@(posedge vif.clk);
								
							end//forever
						end //hijo

			
						begin // -----------hijo pop y pndng -------------
							$display ("Hijo %g iniciado",i);
							@(posedge vif.clk);
							forever begin
							
									//Manejo del pop
									if (vif.pop[0][i]) begin
										trans[i]=subprocesos_entrada[i].pop_front; //saca el primero en la cola	pop					
										vif.D_pop[0] [i]={trans[i].destino,trans[i].dato};
										$display("Se hace un pop cantidad de datos restantes en cola",subprocesos_entrada[i].size());
										$display("		Dipositivo %g",i);
										if (subprocesos_entrada[i].size() > 0)begin //Revisa si quedan pendientes
											vif.pndng[0][i]<=1;
										end else  vif.pndng[0][i]<=0;
									end else begin
										vif.D_pop[0] [i]<={ancho{1'b0}};
									end
															
									//manejo del pending
									if (subprocesos_entrada[i].size() > 0) begin 
										vif.pndng[0][i]<=1;	

									end	else begin 
									  vif.pndng[0][i]<=0;
									end 
								
							
								
								@(posedge vif.clk);
							end//end forever
						end//end hijo


						



						
						
						begin //Hijo Monitor
							@(posedge vif.clk);
							forever begin	
								/////////////////////////////////////////////////
								//Revision si hay algun dato que salga (MONITOR)
								/////////////////////////////////////////////////
							
										
						
									@(posedge vif.push[0][i]); //bloquea hasta que haya un push
									$display ("PUSH =1");
									recibido[i]=new;
									recibido[i].fuente=i; //En este caso la fuente es donde se recibe en mensaje se compara con el destino en teoria
									recibido[i].destino=vif.D_push[0][i][ancho-1:ancho-8] ; //Extrae la direccion del destino que se supone debe ir
									recibido[i].dato=vif.D_push[0][i][ancho-9:0] ; // Extrae del dato recibido de dut el destino original
									recibido[i].tiempo_recibido=$time; 
									recibido[i].print("Driver: transaccion en dispositivo recibida:");
											$display("En dispositivo %g",i);
									drv_chkr_mbx.put(recibido[i]); //se coloca de una vez al mailbox

								
							end	//end del forever de cada subproceso			
						end //end el hijo hijo 
					join_none
				end //end del for	
				//wait fork;
			end
		join_any
	
			
		
	endtask


endclass
