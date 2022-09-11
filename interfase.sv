interface bus_if #(parameter drvrs = 4, parameter pckg_sz=16)(input bit clk, input bit rst);
	//Entradas del bus
	logic pndng [drvrs-1:0];
	logic [pckg_sz-1:0] D_pop [drvrs-1:0];
	
	//Salidas del bus
	logic pop [drvrs-1:0];
	logic push [drvrs-1:0];
	logic [pckg_sz-1:0] D_push [drvrs-1:0];	
endinterface
