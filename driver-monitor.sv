
class driver #(parameter drvrs = 4, parameter ancho = 16);

	virtual bus_if #(.drvrs(drvrs),.pckg_sz(ancho)) vif;
	trans_dut_mbx agnt_drv_mbx;
	trans_dut_mbx drv_chkr_mbx;
	trans_dut #(.ancho(ancho), .drvrs(drvrs)) subprocesos_entrada[drvrs-1:0][$]; //Cola de tipo trans dut para cada dispositivo
	trans_dut #(.ancho(ancho), .drvrs(drvrs)) subprocesos_salida[drvrs-1:0][$]; //No utilizada 
	
	
	trans_dut #(.ancho(ancho), .drvrs(drvrs)) trans[drvrs-1:0]; //Variables temporales para almacenar cada transaccion de la fifo(queue)
	trans_dut #(.ancho(ancho), .drvrs(drvrs)) recibido[drvrs-1:0];
	
	int espera[drvrs-1:0];
	int i=0;	

	task run();
		$display("[%g] El driver fue inicializado",$time);
		@(posedge vif.clk);
		vif.rst=1;;
		@(posedge vif.clk);


		//$display ("Driver: se inician los subprocesos");
		
			
		fork 
			begin
				@(posedge vif.clk);
				forever begin
					trans_dut #(.ancho(ancho), .drvrs(drvrs)) transaccion; //Crea un objeto para almacenar la transaccion siguiente
					$display("[%g] El Driver espera una transaccion",$time);
					@(posedge vif.clk);
					agnt_drv_mbx.get(transaccion);		//espera a que haya algo en el mailbox bloqueando el avance
					transaccion.fuente=0;
					transaccion.destino=0;


					transaccion.print("Driver: Transaccion recibida");	//imprime lo que recibi?? 
					$display("transacciones pendientes en mbx agnt-driver = %g",agnt_drv_mbx.num()); //muestra todas las instrucciones pendientes en el mbx agnt-driver
					
					
					////////////////////////////////////////////////////////////////////////////////////
					/// Division de las instrucciones en diferentes fifos (colas)
					////////////////////////////////////////////////////////////////////////////////////
					
					subprocesos_entrada[transaccion.fuente].push_back(transaccion); //coloca la transaccion en la cola(fifo) correspondiente a la fuente
					$display("		Cantidad de datos en la cola disp[%g]: %g",transaccion.fuente,subprocesos_entrada[transaccion.fuente].size());
					$display("					POP? = %g",vif.pop[0][i]);
					
					
				end //end del forever		
					
			end
			
		
						// inicia la generacion de hijos para cada interfaz
			
				begin
					for (int j=0;j<drvrs;j++)begin  //-----crea los hijos que diga drvrs---------------
						automatic int i=j;
						fork
							begin // Define el inicio del hijo actual
								//@(posedge vif.clk);
								//vif.rst=1;
								//@(posedge vif.clk);
								$display ("Hijo %g iniciado",i);
								@(posedge vif.clk);
								forever begin
									
									vif.pndng[0][i]=0;		//reinicio de variables
									vif.D_pop[0][i]=0;
									vif.rst=0;
									espera[i]=0;
									
									@(posedge vif.clk);
									if (subprocesos_entrada[i].size() > 0) begin //Revisa si hay algo en cola para activar la bandera de pendiente 
										vif.pndng[0][i]=1;	
										//$display("		Pending en dipositivo [%g] = %g",i,vif.pndng[0][i]);
									end	else begin 
									  vif.pndng[0][i]=0;
										$display("		Pending en dipositivo [%g] = %g",i,vif.pndng[0][i]);
									end 
									
									
									if (vif.pop[0][i]==1) begin //Revisa la entrada pop
										$display("		Pop en dipositivo %g",i);
										trans[i]=subprocesos_entrada[i].pop_front; //saca el primero en la cola	pop					
										trans[i].tiempo_envio=$time;
										trans[i].print("Driver: transaccion dispositivo enviada");
										$display("		Dipositivo %g",i);
										while(espera[i] < trans[i].retardo)begin 	//manejo del retardo 
											@(posedge vif.clk);
											espera[i]=espera[i]+1;
											
											if(espera[i]==trans[i].retardo)begin
												$display("		Pop en dipositivo %g",i);
												trans[i]=subprocesos_entrada[i].pop_front; //saca el primero en la cola	pop					
												trans[i].tiempo_envio=$time;
												trans[i].print("Driver: transaccion dispositivo enviada");
												$display("		Dipositivo %g",i);
											end else begin
												//trans[i]=new;
											end
											
											
											
										end 
										vif.D_pop[0][i]={trans[i].destino,trans[i].dato}; //concatenando el destino y dato que necesita recibir el dut ??Poner fuera del while?
										
										if(trans[i].tipo==reset) begin
											@(posedge vif.clk);
											vif.rst=1;
											@(posedge vif.clk);
										end
										
									end	else begin
											vif.D_pop[0][i]={ancho{0}};
										end								
									
								end//forever
							end //hijo
							
							begin
								@(posedge vif.clk);
								forever begin	
									/////////////////////////////////////////////////
									//Revision si hay algun dato que salga (MONITOR)
									/////////////////////////////////////////////////
									
									if (vif.push[0][i])begin
										recibido[i].fuente=i; //En este caso la fuente es donde se recibe en mensaje se compara con el destino en teoria
										recibido[i].destino=vif.D_push[0][i][ancho-1:ancho-8] ; //Extrae la direccion del destino que se supone debe ir
										recibido[i].dato=vif.D_push[0][i][ancho-9:0] ; // Extrae del dato recibido de dut el destino original
										recibido[i].tiempo_recibido=$time; 
										recibido[i].print("Driver: transaccion en dispositivo recibida:");
												$display("En dispositivo %g",i);
										drv_chkr_mbx.put(recibido[i]); //se coloca de una vez al mailbox

									end //if
									
								
								end	//end del forever de cada subproceso			
								
							end //end de cada hijo 
						join_none
					end //end del for	
					wait fork;
				end
			join_any
	
			
		
	endtask


endclass
