
class driver #(parameter drvrs = 4, parameter ancho = 16);
	virtual bus_if #(.drvrs(drvrs),.pckg_sz(ancho)) vif;
	trans_dut_mbx agnt_drv_mbx;
	trans_dut_mbx drv_chkr_mbx;
	trans_dut #(.ancho(ancho)) subprocesos_entrada[drvrs-1:0][$]; //Cola de tipo trans dut para cada dispositivo
	trans_dut #(.ancho(ancho)) subprocesos_salida[drvrs-1:0][$]; //No utilizada 
	
	
	trans_dut #(.ancho(ancho)) trans[drvrs-1:0]; //Variables temporales para almacenar cada transaccion de la fifo(queue)
	trans_dut #(.ancho(ancho)) recibido[drvrs-1:0];
	
	int espera[drvrs-1:0];
	int i;
	
	task run();
		$display("[%g] El driver fue inicializado",$time);
		@(posedge vif.clk);
		vif.rst=1;
		@(posedge vif.clk);
		
		forever begin
			trans_dut #(.ancho(ancho)) transaccion; //Crea un objeto para almacenar la transaccion siguiente
			$display("[%g] El Driver espera una transaccion",$time);
			@(posedge vif.clk);
			agnt_drv_mbx.get(transaccion);		//espera a que haya algo en el mailbox bloqueando el avance
			transaccion.print("Driver: Transaccion recibida");	//imprime lo que recibi?? 
			$display("transacciones pendientes en mbx agnt-driver = %g",agnt_drv_mbx.num()); //muestra todas las instrucciones pendientes en el mbx agnt-driver
			
			
			////////////////////////////////////////////////////////////////////////////////////
			/// Division de las instrucciones en diferentes fifos (colas)
			////////////////////////////////////////////////////////////////////////////////////
			subprocesos_entrada[transaccion.fuente].push_back(transaccion); //coloca la transaccion en la cola(fifo) correspondiente a la fuente
				
			
			
		end //end del forever	
			
		
		fork		// inicia la generacion de hijos para cada interfaz
			$display ("Driver: se inician los subprocesos");
			
			for (int i=0;i<drvrs;i++)begin  //-----crea los hijos que diga drvrs------------------
				
				begin // Define el inicio del hijo actual
					@(posedge vif.clk);
					vif.rst=1;
					@(posedge vif.clk);
				
					forever begin
						
						vif.pndng[i]=0;		//reinicio de variables
						vif.D_pop[i]=0;
						vif.rst=0;
						espera[i]=0;
						
						@(posedge vif.clk);
						if (subprocesos_entrada[i].size() >0) begin //Revisa si hay algo en cola para activar la bandera de pendiente 
							vif.pndng[i]=1;	
						end	else begin 
						  vif.pndng[i]=0;
						end 
						
						
						if (vif.pop==1) begin //Revisa la entrada pop
						
							trans[i]=subprocesos_entrada[i].pop_front; //saca el primero en la cola	pop					
							trans[i].tiempo_envio=$time;
							trans[i].print("[%d] Driver: transaccion dispositivo %d enviada",$time,i);
							while(espera[i] < trans[i].retardo)begin 	//manejo del retardo 
								@(posedge vif.clk);
								espera[i]=espera[i]+1;
								vif.D_pop[i]={trans[i].destino,trans[i].dato}; //concatenando el destino y dato que necesita recibir el dut ??Poner fuera del while?
							end //
							
							
							if(trans[i].tipo==reset) begin
								@(posedge vif.clk);
								vif.rst=1;
								@(posedge vif.clk);
							end
							
						end									
						
						
						/////////////////////////////////////////////////
						//Revision si hay algun dato que salga (MONITOR)
						/////////////////////////////////////////////////
						
						if (vif.push==1)begin
							recibido1.fuente=0; //En este caso la fuente es donde se recibe en mensaje se compara con el destino en teoria
							recibido[i].destino=vif.dato[ancho-1:ancho-8] ; //Extrae la direccion del destino que se supone debe ir
							recibido[i].dato=vif.dato[ancho-9:0] ; // Extrae del dato recibido de dut el destino original
							recibido[i].tiempo_recibido=$time; 
							recibido[i].print("[%d] Driver: transaccion en dispositivo %d recibida:",$time,i);
							drv_chkr_mbx.put(recibido[i]); //se coloca de una vez al mailbox

						end
						
						
					
					end	//end del forever de cada subproceso			
					
				
				end //end de cada hijo 
				
			end //end del for 
			
			
		join_none
			
		
	endtask


endclass
