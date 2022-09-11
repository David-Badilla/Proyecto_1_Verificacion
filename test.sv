
class test #(parameter ancho=16 , parameter drvrs=4);
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
		ambiente_instancia.agente_inst = test_agnt_mbx;

		//Parametros del agente
		ambiente_instancia.agente_inst.num_transacciones = num_transacciones;
		ambiente_instancia.agente_inst.max_retardo=max_retardo;
		
		
		
	endfunction
	
	task run;
		$display("[%d] El Test fue inicializado",$time);
		
		fork
			ambiente_instancia.run();
		join_none
		
		
		instr_agente = genericos;
		test_agnt_mbx.put(instr_agente);
		$display("[%d] Test: Enviada la primera instruccion (genericos)",$time);
		
		
		instr_agente = broadcast_inst;
		test_agnt_mbx.put(instr_agente);
		$display("[%d] Test: Enviada la segunda instruccion (broadcast_inst)",$time);
		
		
		
		instr_agente = Rst_aleatorio;
		test_agnt_mbx.put(instr_agente);
		$display("[%d] Test: Enviada la tercera instruccion (Rst_aleatorio)",$time);
		
		
		instr_agente = Completo;
		test_agnt_mbx.put(instr_agente);
		$display("[%d] Test: Enviada la cuarta instruccion (Completo)",$time);
		
		
		instr_agente = trans_especifica;
		test_agnt_mbx.put(instr_agente);
		$display("[%d] Test: Enviada la quinta instruccion (trans_especifica)",$time);
		
		
		
		#10000
		$display("[%d] Test: Se alcanza el tiempo limite",$time);
		
		//Inician instrucciones al scoreboard para reporte 
		/*		//AUN NO HAY SCOREBOARD
		instr_sb = retraso_promedio //Pueden ser (bwmax) (bwmin) (reporte_completo)
		test_sb_mbx.pu(instr_sb);
		
		instr_sb = bwmax //Pueden ser (bwmax) (bwmin) (reporte_completo)
		test_sb_mbx.pu(instr_sb);
		#20
		*/
		
		$finish;
		
		
	endtask
		
endclass
