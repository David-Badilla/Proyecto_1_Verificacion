
class driver #(parameter drvrs=4, parameter ancho=16, parameter Profundidad_fifo=1000000);
	virtual bus_if #(.drvrs(drvrs),.pckg_sz(ancho)) vif;
	trans_dut_mbx agnt_drv_mbx;
	trans_dut_mbx drv_chkr_mbx;

	bit [ancho-1:0] temporal[drvrs-1:0];
  //Variables para FIFO
	trans_dut_mbx drv_fifos_mbx[drvrs-1:0]; //Mailboxes para pasar datos a los procesos hijos
    fifo #(.pile_size(Profundidad_fifo), .pckg_sz(ancho)) drv_interfaz_fifo [drvrs-1:0]; //Se instancia la clase de fifo
	fifo #(.pile_size(Profundidad_fifo), .pckg_sz(ancho)) fifo_salida[drvrs-1:0]; // FIFO de recepcion 
	
	task run();
        
        $display("[%g] El driver fue inicializado",$time);
    	@(posedge vif.clk);
		vif.rst=1;
		@(posedge vif.clk);
		@(posedge vif.clk);
		@(posedge vif.clk);
		vif.rst=0;
		@(posedge vif.clk);
        //Inicializacion de mailboxes a las interfaces
		for (int i = 0; i < drvrs; i++) begin 
		  drv_fifos_mbx[i] = new();
		end
		
		fork
		  
			begin//------Proceso de recepcion de mensajes ----------
				@(posedge vif.clk);
				forever begin
					trans_dut #(.ancho(ancho),.drvrs(drvrs)) recibido;
	               // $display("[%g] El Driver espera una transaccion",$time);
	      
					//Espera a recibir un mensaje del agente
					agnt_drv_mbx.get(recibido);
					recibido.print("Driver: Transaccion recibida"); //Desplega informacion de mensaje
					$display("	transacciones pendientes en mbx agnt-driver = %g",agnt_drv_mbx.num()); //muestra todas las instrucciones pendientes en el mbx agnt-driver
					drv_fifos_mbx[recibido.fuente].put(recibido); //mete la transaccion al mailbox correspondiente a la fuente
					@(posedge vif.clk);
				
				end //end del forever	
			end// -----------------------------------------------------
			begin  // ############### Hijo para Generacion de subprocesos ##############
		    	for (int j = 0; j < drvrs; j++) begin
		                automatic int i = j;
						
					fork 
		     			begin
		     				interfaz_dispositivo #(.dispositivo(i),.ancho(ancho),.drvrs(drvrs)) interfaz;
		     				interfaz.drv_fifos_mbx=drv_fifos_mbx[i];
		     				interfaz.drv_interfaz_fifo=drv_interfaz_fifo[i];
		     				interfaz.vif=vif;
		     			end
		    	   
			        join_none //join cada dispositivo-intefaz
				end //end del for que genera todos los dispositivos
		  	end // ############### Hijo para Generacion de subprocesos ############## 
		join_none //join de cada proceso (recibir datos y generar las interfaces) 
	endtask
endclass

