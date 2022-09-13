`timescale 1ns/1ps
`include "paquetes.sv"
`include "Library.sv"
`include "interfase.sv"
`include "score_board.sv"
`include "checkr.sv"	//HAY QUE ACOMODARLOS DONDE NO HAYA ERROR EN ORDEN
`include "driver-monitor.sv"
`include "agente.sv"
`include "ambiente.sv"
`include "test.sv"








	/////////////////////////////////
	//Modulo para correr la prueba //
	/////////////////////////////////

module test_bench;
	reg clk;

	//Parametros editables desde aca mas facil
	parameter ancho = 16;
	parameter drvrs =  4;
	parameter broadcast_indi = {8{1'b1}};
	int numero_instrucciones=1000;
	int max_retardo=20;
	instrucciones_agente instr_agente = genericos; //genericos, broadcast_inst , Rst_aleatorio, Completo, trans_especifica uno_todos,todos_uno
	solicitud_sb instr_sb = retraso_promedio;//retraso_promedio, bwmax, bwmin, reporte_completo;




	test #(.ancho(ancho) , .drvrs(drvrs)) t0;	//Instancia clase test
	bus_if #(.pckg_sz(ancho),.drvrs(drvrs))  _if(.clk(clk)); //Instancia interfaz
	always #5 clk=~clk;
	
	//Instanciacion y conexion con el dut con parametros y la interfaz
	bs_gnrtr_n_rbtr #(.drvrs(drvrs),.pckg_sz(ancho), .broadcast(broadcast_indi)) 
		         DUT(.clk(clk),
		             .reset(_if.rst),
		             .pndng(_if.pndng),
		             .push(_if.push),
		             .pop(_if.pop),
		             .D_pop(_if.D_pop),
		             .D_push(_if.D_push) );
		             
		               
	initial begin 
		clk=0;
		t0=new();
		//Conexiones instancias
		t0._if = _if;		
		t0.ambiente_instancia._if=_if;
		t0.ambiente_instancia.driver_inst.vif=_if;
		t0.ambiente_instancia.agente_inst.num_transacciones=numero_instrucciones;
		t0.instr_sb=instr_sb;
		//Conexiones parametros pruebas
		t0.ambiente_instancia.agente_inst.broadcast_id=broadcast_indi;
		t0.ambiente_instancia.agente_inst.max_retardo=max_retardo;
		t0.instr_agente=instr_agente;

		fork
			t0.run();
			
		join_none
	end
		
	always @(posedge clk) begin
		if ($time > 100000) begin
			$display ("[%g] Test_bench: Tiempo limite en el test_bench alcanzado :D",$time);
			$finish;
		
		end	
	end
		
endmodule






