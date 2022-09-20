`timescale 1ns/1ps

`include "interfase.sv"
`include "paquetes.sv"
`include "Library.sv"

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
	parameter drvrs =  5;
	parameter [7:0] broadcast_indi = {8{1'b1}};
	int numero_instrucciones=5; //En general se utiliza esta para todos menos broadcast
	int max_retardo=20;
	instrucciones_agente instr_agente = genericos; //genericos, broadcast_inst , Rst_aleatorio, Completo, trans_especifica, uno_todos,todos_uno
	solicitud_sb instr_sb = bwmin;//retraso_promedio, bwmax, bwmin, reporte_completo;
	
	
	
	//******************HACER CAMBIOS PARA PRUEBAS AQUÍ *********************************
	int Prueba=0; //Prueba 0 deja pasar los datos por defecto de arriba

	//Variables para transaccion especifica




	tipo_trans tpo_spec = generico;	//generico, broadcast, reset,uno_todo,todo_uno
	logic [7:0] fte_spec = 1;
	logic [7:0] dest_spec=2;
	logic [ancho-9:0] dato_spec=8;
	int ret_spec = 25;
	//***********************************************************************************



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


		case(Prueba)
			1:begin instr_agente = genericos; instr_sb = retraso_promedio; end
			2:begin numero_instrucciones = 5; instr_agente =broadcast_inst ; instr_sb = bwmax; end
			3:begin instr_agente = Rst_aleatorio; instr_sb =retraso_promedio ; end
			4:begin instr_agente = Completo; instr_sb = retraso_promedio; end
			5:begin instr_agente = trans_especifica; instr_sb = reporte_completo ; end
			6:begin instr_agente = uno_todos; instr_sb = reporte_completo; end
			7:begin instr_agente = todos_uno; instr_sb = reporte_completo; end
		endcase

		//Conexiones instancias
		t0._if = _if;		
		t0.ambiente_instancia.driver_inst.vif=_if;


		t0.ambiente_instancia.agente_inst.num_transacciones=numero_instrucciones;
		t0.instr_sb=instr_sb; //Para seleccionar la instruccion manual
		//Conexiones parametros pruebas
		t0.ambiente_instancia.agente_inst.broadcast_id=broadcast_indi;
		t0.ambiente_instancia.agente_inst.max_retardo=max_retardo;
		t0.instr_agente=instr_agente;
	

		t0.ambiente_instancia.agente_inst.tpo_spec=tpo_spec;
		t0.ambiente_instancia.agente_inst.fte_spec=fte_spec;
		t0.ambiente_instancia.agente_inst.dest_spec=dest_spec;
		t0.ambiente_instancia.agente_inst.dato_spec=dato_spec;
		t0.ambiente_instancia.agente_inst.ret_spec=ret_spec;
	


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






