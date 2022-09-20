
class test #(parameter ancho=16 , parameter drvrs=5);
	instrucciones_agente_mbx test_agnt_mbx;		//Test===> Agente/Generador
	solicitud_sb_mbx test_sb_mbx;				//Test===> Scoreboard
	
	parameter num_transacciones=3;
	parameter max_retardo = 20;
	
	
	solicitud_sb orden;  				//orden a solicitar al scoreboard
	instrucciones_agente instr_agente; 	//instruccion para enviar a ejecutar secuencias
	solicitud_sb instr_sb;
	
	// Definicion del ambiente de la prueba
	ambiente #(.ancho(ancho) , .drvrs(drvrs)) ambiente_instancia;
	
	// Definicion de la interface a conectar en el DUT
	virtual bus_if #(.drvrs(drvrs) , .pckg_sz(ancho)) _if;
	
	// Definicion de las condiciones iniciales del test 
	function new;
		//Iniciando mailboxes
		test_agnt_mbx	= new();
		test_sb_mbx		= new();
		
		
		// Definicion y conexion del driver
		ambiente_instancia = new();
		ambiente_instancia._if = _if;
		ambiente_instancia.test_sb_mbx = test_sb_mbx; 
		ambiente_instancia.scoreboard_inst.test_sb_mbx = test_sb_mbx;

		ambiente_instancia.test_agnt_mbx = test_agnt_mbx;
		ambiente_instancia.agente_inst.test_agent_mbx = test_agnt_mbx;

		//Parametros del agente
		ambiente_instancia.agente_inst.num_transacciones = num_transacciones;
		ambiente_instancia.agente_inst.max_retardo=max_retardo;
		
		
		
	endfunction
	
	task run;
		$display("[%g] El Test fue inicializado",$time);
		
		fork
			ambiente_instancia.run();
		join_none
		
		case(instr_agente) //Case para tener más controlado que tipo de instruccion se va a realizar
			genericos:begin
				test_agnt_mbx.put(instr_agente);
				$display("[%g] Test: Enviada la primera instruccion (genericos)",$time);
			end
			
			
			broadcast_inst:begin
				test_agnt_mbx.put(instr_agente);
				$display("[%g] Test: Enviada la segunda instruccion (broadcast_inst)",$time);
			end		
			
			
			Rst_aleatorio:begin
				test_agnt_mbx.put(instr_agente);
				$display("[%g] Test: Enviada la tercera instruccion (Rst_aleatorio)",$time);
			end		
			
			Completo:begin
				test_agnt_mbx.put(instr_agente);
				$display("[%g] Test: Enviada la cuarta instruccion (Completo)",$time);
			end			
			
			trans_especifica:begin
				test_agnt_mbx.put(instr_agente);
				$display("[%g] Test: Enviada la quinta instruccion (trans_especifica)",$time);
			end
			uno_todos:begin
				test_agnt_mbx.put(instr_agente);
				$display("[%g] Test: Enviada la sexta instruccion (uno_todos)",$time);
			end
			
			todos_uno:begin
				test_agnt_mbx.put(instr_agente);
				$display("[%g] Test: Enviada la setima instruccion (todos_uno)",$time);
			end
			default: begin
				$error("No se seleccionó ninguna instruccion");
				$finish;
			end

		endcase
		
		
		#10000
		$display("[%g] Test: Se alcanza el tiempo limite",$time);
		
		//Inician instrucciones al scoreboard para reporte 
		case(instr_sb)
			reporte_completo: test_sb_mbx.put(instr_sb); //Pueden ser (bwmax) (bwmin) (reporte_completo)
			retraso_promedio:test_sb_mbx.put(instr_sb);
			bwmax:test_sb_mbx.put(instr_sb);
			bwmin:test_sb_mbx.put(instr_sb);
		endcase		


		//instr_sb = bwmax; //Pueden ser (bwmax) (bwmin) (reporte_completo)
		//test_sb_mbx.put(instr_sb);
		#20
		
		
		$finish;
		
		
	endtask
		
endclass
