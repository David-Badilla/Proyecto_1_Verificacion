

class agente #(parameter ancho=16, parameter drvrs=4);
	trans_dut_mbx agnt_drv_mbx;  	//mbx agente - driver
	instrucciones_agente_mbx test_agent_mbx; //mbx test - agente
	
	int num_transacciones;
	int max_retardo;
	bit [7:0] broadcast_id; //*****COLOCAR LUEGO COMO PARAMETRO RECIBIDO***
	instrucciones_agente instruccion;
	trans_dut #(.ancho(ancho), .drvrs(drvrs)) transaccion;
	
	//Variables especificas para trans_especifica
	tipo_trans tpo_spec;
	bit [7:0] fte_spec;
	bit [7:0] dest_spec;
	bit [ancho-9:0] dato_spec;
	int ret_spec;
	
	
	
	function new;
		num_transacciones=1;
		max_retardo=20;
		broadcast_id = {8{1'b1}};
	endfunction

	
	task run;
		$display("[%g] El Agente fue inicializado",$time);
		forever begin
			#2
			if(test_agent_mbx.num() > 0)begin
				$display("[%g] Agente: se recibe instruccion",$time);
				test_agent_mbx.get(instruccion);
				
				case(instruccion)
					genericos: begin //aleatorio comun
						for (int i=0;i < num_transacciones;i++)begin
							transaccion=new;
							transaccion.max_retardo=max_retardo;
							transaccion.randomize();
							transaccion.tipo=generico; // se fuerza a que sea de tipo generico
							transaccion.print("Agente:transaccion creada");
							agnt_drv_mbx.put(transaccion);
						end
						
					end
					
					
					broadcast_inst: begin  // Enviar packetes exclusivos de broadcast
						for (int i=0;i < 10-8;i++)begin  //LIMITAR A 10 LO DIJO EL PROFE
							transaccion=new;
							transaccion.max_retardo=max_retardo;
							transaccion.randomize();
							transaccion.tipo=broadcast;
							transaccion.destino=broadcast_id;  //define que sea de tipo broadcast
							transaccion.print("Agente:transaccion (broadcast) creada");
							agnt_drv_mbx.put(transaccion);
						end
						
					end
					
					Rst_aleatorio: begin
						for (int i=0;i < num_transacciones;i++)begin
							transaccion=new;
							transaccion.max_retardo=max_retardo;
							transaccion.randomize();
							transaccion.tipo=reset;// se fuerza a que sea de tipo reset
							transaccion.print("Agente:transaccion (reset) creada");
							agnt_drv_mbx.put(transaccion);
							
						end
						
						
					end
					
					
					Completo: begin
						for (int i=0;i < num_transacciones;i++)begin
							transaccion=new;
							transaccion.max_retardo=max_retardo;
							transaccion.randomize(); // aqui mismo de aleatoriza si es generico , broadcast o reset
							if(transaccion.tipo==broadcast) begin 
								transaccion.destino=broadcast_id; // para colocar el identificador de broadcast
							end
							transaccion.print("Agente:transaccion (completa) creada");
							agnt_drv_mbx.put(transaccion);	
						end
							
					end
					
					trans_especifica: begin
						transaccion=new;
						transaccion.tipo=tpo_spec;
						transaccion.fuente= fte_spec;
						transaccion.destino= dest_spec;
						transaccion.dato=dato_spec;
						transaccion.retardo= ret_spec;
						transaccion.print("Agente:transaccion (Especifica) creada");
						agnt_drv_mbx.put(transaccion);		
												
					end			
					
				endcase
				
			end //end if
		
		end //end forever
	
	endtask

endclass
