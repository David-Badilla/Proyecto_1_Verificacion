class ambiente #(parameter ancho=16 , parameter drvrs=4);
	//-----------Componentes del ambiente---------------------------------
	driver #(.ancho(ancho), .drvrs(drvrs)) driver_inst;
	agente #(.ancho(ancho)) agente_inst;
	//score_board #(.ancho(ancho)) scoreboard_inst;
	//Checker #(.ancho(ancho)) Checker_inst; //OJO CON LA MAYUSCULA
	
	
	//-----------Declaracion de la interface que conecta el dut-----------
	virtual bus_if #(.drvrs(drvrs), .pckg_sz(ancho)) _if;
	
	//-----------Declaracion de los mailboxes-----------------------------
	trans_dut_mbx agnt_drv_mbx;				//Mailbox del agente al driver
	trans_dut_mbx drv_chkr_mbx;				//Mailbox del driver al checker
	trans_sb_mbx  chkr_sb_mbx;				//Mailbox del checker al scoreboard
	instrucciones_agente_mbx test_agnt_mbx;	//Mailbox del test al agente
	solicitud_sb_mbx test_sb_mbx;			//Mailbox del test al scoreboard
	
	function new();
		//-----------Inicializando los mailboxes-----------
		agnt_drv_mbx	= new();
		drv_chkr_mbx	= new();
		chkr_sb_mbx		= new();
		test_agnt_mbx	= new();
		test_sb_mbx		= new();
		
		//-----------Inicializando los componentes del ambiente (modulos)---
		driver_inst			= new();
		agente_inst			= new();
		//scoreboard_inst	= new();
		//Checker_inst		= new();
		
		
		//-----------Conexion de las interfaces y mailboxes en el ambiente---
		driver_inst.vif 			= _if;
		
		driver_inst.agnt_drv_mbx	= agnt_drv_mbx;
		driver_inst.drv_chkr_mbx	= drv_chkr_mbx;
		
		agente_inst.test_agnt_mbx	= test_agnt_mbx;
		agente_inst.agnt_drv_mbx	= agnt_drv_mbx;
		
		
		//Checker_inst.chkr_sb_mbx 	= chkr_sb_mbx;		//Faltan hacer
		//Checker_inst.drv_chkr_mbx	= drv_chkr_mbx;
		
		//scoreboard_inst.chkr_sb_mbx	= chkr_sb_mbx;
		//scoreboard_inst.test_sb_mbx	= test_sb_mbx;
	
	endfunction
	
	virtual task run();
		$display("[%d] El ambiente fue inicializado",$time);
		fork
			driver_inst.run();
			agente_inst.run();
			//Checker_inst.run();
			//scoreboard_inst.run();
		join_none
	
	endtask
endclass
