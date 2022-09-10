

class driver #(parameter drvrs = 4 parameter ancho = 16);
	virtual bus_if #(.drvrs(drvrs),.pckg_sz(ancho)) vif;
	trans_dut_mbx agnt_drv_mbx;
	trans_dut_mbx drv_chkr_mbx;
	trans_dut_mbx subprocesos[drvrs-1:0];
	
	int espera;
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
			$display("transacciones pendientes en mbx agnt-driver = %g",agnt_drv_mbx.num()); //muestra todas las instrucciones pendientes
			
			
			////////////////////////////////////////////////////////////////////////////////////
			/// Apartir de aqui ni idea como implemetar todos los fork hijos para cada interface
			////////////////////////////////////////////////////////////////////////////////////
			while(espera < transaccion.retardo)begin 	//manejo del retardo
				@(posedge vif.clk);
				espera=espera+1;
			end // 
			
			
			
			
			//IDEA NO TOMAR EN CUENTA
			
			fork		//Idea generar siempre los 16 procesos diferentes aunque no se usen
				begin //Dispositivo 1 
				
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
			
		
		
		
		
		
		end //end del forever
	
	
	
	endtask













endclass
