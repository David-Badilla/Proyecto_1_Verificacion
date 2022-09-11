interface bus_if #(parameter drvrs = 4, parameter pckg_sz=16)(input bit clk);
	//Entradas del bus
	logic rst;
	logic pndng[0:0][drvrs-1:0];  //[0] es de el array bits
	logic [pckg_sz-1:0] D_pop [0:0][drvrs-1:0];
	
	//Salidas del bus
	logic pop [0:0][drvrs-1:0];
	logic push [0:0][drvrs-1:0];
	logic [pckg_sz-1:0] D_push[0:0][drvrs-1:0];	
endinterface
