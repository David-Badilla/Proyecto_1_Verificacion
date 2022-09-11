`timescale 1ns/1ps
`include "paquetes.sv"
`include "Library.sv"
`include "interfase.sv"
`include "driver-monitor.sv"
`include "agente.sv"
`include "ambiente.sv"
`include "test.sv"


`include "checker.sv"	//HAY QUE ACOMODARLOS DONDE NO HAYA ERROR EN ORDEN

`include "score_board.sv"


	/////////////////////////////////
	//Modulo para correr la prueba //
	/////////////////////////////////

module test_bench;
	reg clk;
	parameter ancho = 16;
	parameter drvrs =  4;
	parameter broadcast_indi = {8{1'b1}};
	
	test #(.ancho(ancho) , .drvrs(drvrs)) t0;	//Instancia clase test
	bus_if #(.pckg_sz(ancho),.drvrs(drvrs))  _if(.clk(clk)); //Instancia interfaz
	always #5 clk=~clk;
	
	//Instanciacion y conexion con el dut con parametros y la interfaz
	bs_gnrtr_n_rbtr #(.drvrs(drvrs),.pckg_sz(ancho), .broadcast(broadcast_indi)) 
		         DUT(.clk(clk/*_if.clk*/),
		             .reset(_if.rst),
		             .pndng(_if.pndng),
		             .push(_if.push),
		             .pop(_if.pop),
		             .D_pop(_if.D_pop),
		             .D_push(_if.D_push) );
		             
		               
	initial begin 
		clk=0;
		t0=new();
		t0._if = _if;
		t0.ambiente_instancia._if=_if;
		
		fork
			t0.run();
			
		join_none
	end
		
	always @(posedge clk) begin
		if ($time > 100000) begin
			$display ("[%d] Test_bench: Tiempo limite en el test_bench alcanzado :D",$time);
			$finish;
		
		end	
	end
		
endmodule






