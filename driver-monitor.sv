
class driver #(parameter drvrs = 4, parameter ancho = 16);

	virtual bus_if #(.drvrs(drvrs),.pckg_sz(ancho)) vif;
	trans_dut_mbx agnt_drv_mbx;
	trans_dut_mbx drv_chkr_mbx;
	trans_dut #(.ancho(ancho), .drvrs(drvrs)) subprocesos_entrada[drvrs-1:0][$]; //Cola de tipo trans dut para cada dispositivo
	trans_dut #(.ancho(ancho), .drvrs(drvrs)) subprocesos_salida[drvrs-1:0][$]; //No utilizada 
	
	
	trans_dut #(.ancho(ancho), .drvrs(drvrs)) trans[drvrs-1:0]; //Variables temporales para almacenar cada transaccion de la fifo(queue)
	trans_dut #(.ancho(ancho), .drvrs(drvrs)) Retardoins[drvrs-1:0];
	trans_dut #(.ancho(ancho), .drvrs(drvrs)) recibido[drvrs-1:0];
	 bit [ancho-1:0] transa[drvrs-1:0];
	int espera[drvrs-1:0];
	task run();
		$display("[%g] El driver fue inicializado",$time);
		@(posedge vif.clk);
		vif.rst=1;
		@(posedge vif.clk);
		@(posedge vif.clk);
		@(posedge vif.clk);
		vif.rst=0;
		@(posedge vif.clk);
		
		for (int i = 0; i < drvrs; i++) begin 
			Retardoins[i]=new;
      		trans[i] = new;
			vif.pndng[0][i]=0;
			//vif.D_pop[0][i]={4'b0001,4'b0010};

	    end
		//$display ("Driver: se inician los subprocesos");
		
			
		fork 
			begin //Hijo para rebicion de transaccion entrante de mbx
				@(posedge vif.clk);
				forever begin
					trans_dut #(.ancho(ancho), .drvrs(drvrs)) transaccion = new; //Crea un objeto para almacenar la transaccion siguiente
					$display("[%g] El Driver espera una transaccion",$time);
					//@(posedge vif.clk);
					agnt_drv_mbx.get(transaccion);		//espera a que haya algo en el mailbox bloqueando el avance
					transaccion.fuente=1;
					transaccion.destino=3;


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
											Retardoins[i].tiempo_envio=$time;										
											subprocesos_entrada[i].push_back(Retardoins[i]);						
										end 	
									end //end while
								end else begin
									Retardoins[i]=new;
								end
								//@(posedge vif.clk);
								@(posedge vif.clk);
								
							end//forever
						end //hijo

			
						begin // -----------hijo pop y pndng -------------
							$display ("Hijo %g iniciado",i);
							@(posedge vif.clk);
							//vif.D_pop[0] [i]<={ancho{1'b0}};
							forever begin
									
									//Manejo del pop
									@(posedge vif.pop[0][i]);
									if (vif.pop[0][i]) begin
										//vif.D_pop[0][i]={ancho{1'b0}};
										trans[i]=new;
										//transa={ancho{1'b0}};
										trans[i]=subprocesos_entrada[i].pop_front; //saca el primero en la cola	pop										
										transa[i]={trans[i].destino,trans[i].dato};
										trans[i].print("	Dato en D_pop");
										$display("			Dpop concat dest %b dat= %b = %b",trans[i].destino,trans[i].dato,transa[i]);

										vif.D_pop[0][i]=transa[i];
										$display("		Se hace un pop cantidad de datos restantes en cola[%g] =",i,subprocesos_entrada[i].size());
										$display("		Dipositivo %g",i);
										if (subprocesos_entrada[i].size() > 0)begin //Revisa si quedan pendientes
											vif.pndng[0][i]=1;
										end else begin
											vif.pndng[0][i]=0;
										end
									end 
									
						
								
								//@(posedge vif.clk);
								
							end//end forever
						end//end hijo

						begin//manejo del pending
							//@(posedge vif.clk);
							//vif.pndng[0][i]=0;
							forever begin

								if (subprocesos_entrada[i].size() > 0) begin 
										vif.pndng[0][i]=1;	

									end	else begin 
										vif.pndng[0][i]=0;
									end 
								@(posedge vif.clk);

							end
						end



						
						
						begin //Hijo Monitor
							//@(posedge vif.clk);
							forever begin	
								/////////////////////////////////////////////////
								//Revision si hay algun dato que salga (MONITOR)
								/////////////////////////////////////////////////

									@(vif.push[0][i]); //bloquea hasta que haya un push
									$display ("PUSH =1 en Disp[%g]",i);
									recibido[i]=new;
									recibido[i].fuente=i; //En este caso la fuente es donde se recibe en mensaje se compara con el destino en teoria
									recibido[i].destino=vif.D_push[0][i][ancho-1:ancho-8] ; //Extrae la direccion del destino que se supone debe ir
									recibido[i].dato=vif.D_push[0][i][ancho-9:0] ; // Extrae del dato recibido de dut el destino original
									recibido[i].tiempo_recibido=$time; 
									recibido[i].print("Driver: transaccion recibida y enviada al checker:");
											$display("En dispositivo %g",i);
									drv_chkr_mbx.put(recibido[i]); //se coloca de una vez al mailbox

								
							end	//end del forever de cada subproceso			
						end //end el hijo hijo 
					join_none
					
				end //end del for	
				//wait fork;
			end
		join
	
			
		
	endtask


endclass
