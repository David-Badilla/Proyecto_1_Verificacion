

class driver #(parameter drvrs = 4, parameter ancho = 16);
	virtual bus_if #(.drvrs(drvrs),.pckg_sz(ancho)) vif;
	trans_dut_mbx agnt_drv_mbx;
	trans_dut_mbx drv_chkr_mbx;
	trans_dut #(.ancho(ancho)) subprocesos_entrada[15:0][$]; //Cola de tipo trans dut para cada dispositivo
	trans_dut #(.ancho(ancho)) subprocesos_salida[15:0][$]; //No utilizada 
	
	
	int espera[15:0];
	int i;
	
	task run();
		$display("[%g] El driver fue inicializado",$time);
		@(posedge vif.clk);
		vif.rst=1;
		@(posedge vif.clk);
		
		forever begin
			trans_dut #(.ancho(ancho)) transaccion; //Crea un objeto para almacenar la transaccion siguiente
			
			for(i=0; i < drvrs ; i++)begin  //Reinicio de las variables de todos los buses  *Revisar bien no estoy seguro*
				vif.D_pop[i]=0;
				vif.pop[i]=0;
				vif.push[i]=0;
				vif.rst[i]=0;
			end
			
			
			$display("[%g] El Driver espera una transacción",$time);
			espera=0;

			@(posedge vif.clk);
			agnt_drv_mbx.get(transaccion);		//espera a que haya algo en el mailbox bloqueando el avance
			transaccion.print("Driver: Transaccion recibida");	//imprime lo que recibió 
			$display("transacciones pendientes en mbx agnt-driver = %g",agnt_drv_mbx.num()); //muestra todas las instrucciones pendientes en el mbx agnt-driver
			
			
			////////////////////////////////////////////////////////////////////////////////////
			/// Division de las instrucciones en diferentes fifos (colas)
			////////////////////////////////////////////////////////////////////////////////////
			subprocesos_entrada[transaccion.fuente].push_back(transaccion); //coloca la transaccion en la cola(fifo) correspondiente a la fuente
				
			
			
		end //end del forever	
			
			//-----------------IDEA NO TOMAR EN CUENTA---------------------
			fork		//Idea generar siempre los 16 procesos diferentes aunque no se usen		
				$display ("Driver: se inician los subprocesos");
				begin //Dispositivo 1 
					@(posedge vif.clk);
					vif.rst=1;
					@(posedge vif.clk);
				
					forever begin
						trans_dut #(.ancho(ancho)) tran1;
						trans_dut #(.ancho(ancho)) recibido1;
						
						vif.pndng[0]=0;
						vif.D_pop[0]=0;
						//vif.pop[0]=0; No por que es una señal que se recibe desde el dut
						//vif.push[0]=0; No por que es una señal que se recibe desde el dut
						vif.rst=0;
						espera[0]=0;
						@(posedge vif.clk);
						if (subprocesos_entrada[0].size() >0);begin //Revisa si hay algo en cola para activar la bandera de pendiente 
							vif.pndng[0]=1;
							
						end					
						else vif.pndng[0]=0;
						
						if (vif.pop==1) begin //Revisa la entrada pop
						
							tran1=subprocesos_entrada[0].pop_front; //saca el primero en la cola						
							tran1.tiempo_envio=$time;
							tran1.print("Driver: transaccion dispositivo 1 recibida");
							while(espera[0] < tran1.retardo)begin 	//manejo del retardo  subprocesos_entrada[0][0] segundo 0 para siempre mantenerse en la instruccion primera de la cola
								@(posedge vif.clk);
								espera[0]=espera[0]+1;
								vif.D_pop[0]={tran1.destino,tran1.dato}; //concatenando el destino y dato que necesita recibir el dut ¿Poner fuera del while?
							end //
							
							
							if(tran1.tipo==reset) begin
								vif.rst=1;
							end
							
						end									
						
						
						/////////////////////////////////////////////////
						//Revision si hay algun dato que salga (MONITOR)
						/////////////////////////////////////////////////
						
						if (vif.push==1)begin
							recibido1.fuente=0; //En este caso la fuente es donde se recibe en mensaje se compara con el destino en teoria
							recibido1.destino=[ancho:ancho-6] vif.dato;
							recibido1.dato=[ancho-6:0] vif.dato;
							recibido1.tiempo_recibido=$time; 

							drv_chkr_mbx.put(recibido); //se coloca de una vez al mailbox

						end
						
						
						
						
						
					end				
					
					
					
				end
				
				
				begin //Dispositivo 2 
				
				end
				
				
				begin //Dispositivo 3 
				
				end
				
				begin //Dispositivo 4 
				
				end
				
				begin //Dispositivo 5 
				
				end
				
				begin //Dispositivo 6 
				
				end
				
				
				begin //Dispositivo 7 
				
				end
				
				begin //Dispositivo 8 
				
				end
				
				begin //Dispositivo 9 
				
				end
				
				begin //Dispositivo 10 
				
				end
				
				begin //Dispositivo 11
				
				end
				
				begin //Dispositivo 12
				
				end
				
				begin //Dispositivo 13
				
				end
				
				begin //Dispositivo 14
				
				end
				
				begin //Dispositivo 15
				
				end
				
				begin //Dispositivo 16
			
				end
				
				
				
			
			
			
			join_none
			
		
		
		
		
		
		
	
	
	
	endtask













endclass
