
class driver #(parameter drvrs=4, parameter ancho=16, parameter Profundidad_fifo=1000000);
	virtual bus_if #(.drvrs(drvrs),.pckg_sz(ancho)) vif;
	trans_dut_mbx agnt_drv_mbx;
	trans_dut_mbx drv_chkr_mbx;

	bit [ancho-1:0] temporal[drvrs-1:0];
  //Variables para FIFO
	mailbox drv_fifos_mbx[drvrs-1:0]; //Mailboxes para pasar datos a los procesos hijos
    fifo #(.pile_size(Profundidad_fifo), .pckg_sz(ancho)) drv_interfaz_fifo [drvrs-1:0]; //Se instancia la clase de fifo
	fifo #(.pile_size(Profundidad_fifo), .pckg_sz(ancho)) fifo_salida[drvrs-1:0]; // FIFO de recepcion 

	trans_dut #(.ancho(ancho),.drvrs(drvrs)) transaccion[drvrs-1:0];
	trans_dut #(.ancho(ancho),.drvrs(drvrs)) trans_recibida[drvrs-1:0];
	
  task run();
        
        $display("[%g] El driver fue inicializado",$time);
    	@(posedge vif.clk);
		vif.rst=1;
		@(posedge vif.clk);
		@(posedge vif.clk);
		@(posedge vif.clk);
		vif.rst=0;
		@(posedge vif.clk);
		@(posedge vif.clk);
        //Inicializacion de mailboxes y FIFOs
    for (int i = 0; i < drvrs; i++) begin 
      drv_fifos_mbx[i] = new();
      drv_interfaz_fifo[i] = new();
    end
    
    fork
      //Proceso de recepcion de mensajes 
		begin
			@(posedge vif.clk);
				forever begin
					trans_dut #(.ancho(ancho),.drvrs(drvrs)) recibido=new;
                   // $display("[%g] El Driver espera una transaccion",$time);
          
					//Espera a recibir un mensaje del agente
					agnt_drv_mbx.get(recibido);
					recibido.print("Driver: Transaccion recibida"); //Desplega informacion de mensaje
					$display("	transacciones pendientes en mbx agnt-driver = %g",agnt_drv_mbx.num()); //muestra todas las instrucciones pendientes en el mbx agnt-driver
					drv_fifos_mbx[recibido.fuente].put(recibido); //mete la transaccion al mailbox correspondiente a la fuente
					@(posedge vif.clk);
				
				end //end del forever	
		end
      
      //Proceso de los FIFO 
		begin  // ############### Hijo para Generacion de subprocesos ##############
        	for (int j = 0; j < drvrs; j++) begin
                    automatic int i = j;
					fifo_salida[i] = new(); 
        	  fork 
         
        	    begin //-------------------Inicia hijo para manejo de retardo-------------------
	    	      automatic bit [ancho-1:0] paquete; //Variable de datos para la fifo de entrada
	          int delay = 0; //variable de retraso
	                        @(posedge vif.clk);
	                        forever begin
	                            transaccion[i]=new; 
	                            delay = 0;  
	                            @(posedge vif.clk);
	                            drv_fifos_mbx[i].get(transaccion[i]); //Saca la transaccion actual del mbx                          
								
								paquete[ancho-1:ancho-8] = transaccion[i].destino;
	                            paquete[ancho-9:0] = transaccion[i].dato;
	                          
	            				//Ciclos de retraso
	                            while(delay <= transaccion[i].retardo)begin
									if(transaccion[i].tipo==reset) vif.rst=1;  //Revisa si el tipo es reset para aplicarlo durante el retardo
	                              	if(delay == transaccion[i].retardo)begin //Cuando se completa el retardo
										vif.rst=0;
	                                    drv_interfaz_fifo[i].push(paquete); // se coloca el dato en la fifo de entrada 
	                                    break;  
	              					end
	                                @(posedge vif.clk);
	                                delay =  delay + 1;
	            				end
	                        end
	                    end//-------------------Termina hijo manejo de retardo-------------------
	        
	                    begin//*****************Hijos para manejo de pop*************************
	                        @(posedge vif.clk);
	                      forever begin
	                        	
	                            @(posedge vif.clk);                                       
	                        	if(vif.pop[0][i])begin
	                          		vif.D_pop[0][i] = drv_interfaz_fifo[i].pop();
	                              	vif.pndng[0][i] <= drv_interfaz_fifo[i].get_pndg();
							    end else begin
	                              	vif.D_pop[0][i] <= drv_interfaz_fifo[i].pile[$]; 
	                            end
	                            //manejo de bandera de pndng
	                            if(drv_interfaz_fifo[i].get_pndg() == 1) begin
	                              	vif.pndng[0][i] <= 1;
	                            end else begin
	                              	vif.pndng[0][i] <= 0;
	                            end
	                        
	                        end
	                    end// *****************Temina hijo manejos de pop****************************



						begin // +++++++++++++++++++Hijo manejo de push (Monitor)++++++++++++++++++++++++++
	          				@(posedge vif.clk);
	            			forever begin                 
	                          	
	                          	@(vif.push[0][i]); //Espera a recibir un push
	                          	//PUSH a la fifo del dato recibido del dut
	                              	fifo_salida[i].push(vif.D_push[0][i]);
									@(posedge vif.clk);
									@(posedge vif.clk);
	                        end
	                    end// +++++++++++++++++++Termina Hijo manejo de push (Monitor)++++++++++++++++++++++++++
	                  	begin //----------------Inicia hijo que maneja el envio al checker-----------------------
	                      	@(posedge vif.clk);
	                    	forever begin
	                          	//POP de la fifo de salida para enviarla al mbx checher
								trans_recibida[i] = new();
	                          	@(posedge vif.clk);
	                    		if(fifo_salida[i].get_pndg())begin
	                              	temporal[i] = fifo_salida[i].pop();  //Recibe de la fifo de salida el destino + dato  
									trans_recibida[i].destino=temporal[i][ancho-1:ancho-8];
	                        		trans_recibida[i].dato = temporal[i][ancho-9:0];
	                        		trans_recibida[i].tiempo_recibido = $time;
	                        		trans_recibida[i].fuente = i;
									trans_recibida[i].print("Driver: Se coloca transaccion para el checker");
	                       	 		drv_chkr_mbx.put(trans_recibida[i]);
									//$display("transacciones pendientes en mbx driver-checker = %g",drv_chkr_mbx.num()); //muestra todas las instrucciones pendientes en el mbx agnt-driver
	                    		end
	            			end 
	                    end //----------------Termina hijo que maneja el envio al checker-----------------------
	                join_none //join cada dispositivo-intefaz
	    		end //end del for que genera todos los dispositivos
      		end // ############### Hijo para Generacion de subprocesos ############## 
    	join_none //join de cada proceso (recibir datos-retardo-hacer pop - push) 
  	endtask
endclass

