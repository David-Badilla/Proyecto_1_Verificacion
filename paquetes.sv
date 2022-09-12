///////////////////////////////////////////////
//Definicion tipos posibles de transacciones 
///////////////////////////////////////////////
typedef enum {generico, broadcast, reset} tipo_trans;

///////////////////////////////////////////////////////////////////////////////////////////
//Paquete TransDUT (pck1) Agente/generador ---> Driver/Monitor y Diver/Monitor ---> Checker
///////////////////////////////////////////////////////////////////////////////////////////
class trans_dut #(parameter ancho=16, parameter drvrs=4);
	rand tipo_trans tipo;
	rand bit [ancho-9:0] dato; //-6 para los 5 bits que hay que concatenar de direccion
	rand bit [7:0] fuente;
	rand bit [7:0] destino;
	rand int retardo;
	int tiempo_envio;
	int tiempo_recibido;
	int max_retardo;	//Retardo maximo de 20
	
	constraint const_retardo {retardo<max_retardo; retardo>0;}
	constraint const_destino {destino != fuente; destino<drvrs; destino>0;} 			 // Restriccion del destino 
	constraint const_fuente {fuente<drvrs;fuente>0;} //la fuente debe existir 



	function new (tipo_trans tpo = generico, bit [ancho-9:0] dto =0 , bit [7:0] fte = 0 , bit [7:0] dstn=1, int ret=0, int t_envio=0,int t_recibido=0 , int max_ret=20);
		this.tipo = tpo;
		this.dato = dto; 
		this.fuente = fte;
		this.destino = dstn;
		this.retardo = ret;
		this.tiempo_envio = t_envio;
		this.tiempo_recibido = t_recibido;
		this.max_retardo = max_ret;		
		
	endfunction
	
	
	function void print(string tag ="");
		$display("[%g] %s Tiempo-Envio=%g Tiempo-Recibido=%g Tipo=%s Retardo=%g Fuente=%g Destino=%g dato=0x%g", $time,tag,this.tiempo_envio, this.tiempo_recibido, this.tipo, this.retardo, this.fuente, this.destino, this.dato);
		
	endfunction
		 
endclass	
	
/////////////////////////////////////////////////////////////////////
// Definicion del paquete Trans_sb Checker--> ScoreBoard 
/////////////////////////////////////////////////////////////////////
class trans_sb #(parameter ancho = 16);
	bit [ancho-9:0] dato_enviado;
	bit [7:0] Fuente;
	bit [7:0] Destino;
	int tiempo_envio;
	int tiempo_recibido;
	int latencia;
	
	function clean();
		this.dato_enviado=0;
		this.Fuente=0;
		this.Destino=0;
		this.tiempo_envio=0;
		this.tiempo_recibido=0;
		this.latencia=0;
	endfunction
	
	task calc_latencia;
		this.latencia=this.tiempo_recibido - this.tiempo_envio;
	endtask
	
	function print(string tag); //Funcion para imprimir el contenido del objeto Trans_sb
		$display ("[%g] %s Dato=0x%h Fuente_Recibido=%g Destino_teorico=%g T_envio=%g T_recibido=%g Latencia=%g", 
			$time,
			tag,
			this.dato_enviado,
			this.Fuente,
			this.Destino,
			this.tiempo_envio,
			this.tiempo_recibido,
			this.latencia
			);
		
		
	endfunction
endclass



///////////////////////////////////////////////
// Definicion de la transaccion pck4 Test-->Agente/Generador usando typedef 
///////////////////////////////////////////////
typedef enum {genericos, broadcast_inst , Rst_aleatorio, Completo, trans_especifica} instrucciones_agente; //completo es todo junto ***Se le cambio el nombre al broadcast porque ya habia uno igual***

///////////////////////////////////////////////
// Transaccion pck5 Test --> Scoreboard
///////////////////////////////////////////////
typedef enum {retraso_promedio, bwmax, bwmin, reporte_completo} solicitud_sb;




///////////////////////////////////////////////
// Definicion mailbox 
///////////////////////////////////////////////
typedef mailbox #(trans_dut) trans_dut_mbx;  //agente/generador ===> driver/monitor ===>Checker

typedef mailbox #(trans_sb) trans_sb_mbx;  //Checker ===> Scoreboard

typedef mailbox #(instrucciones_agente) instrucciones_agente_mbx;  //Test===> Agente/Generador
typedef mailbox #(solicitud_sb) solicitud_sb_mbx;//Test===> Scoreboard

	
	
	
	
	
	
	
	
	
	
	






class fifo #(parameter pile_size = 5, parameter pckg_sz = 32);
	bit fifo_full;		//Bandera de lleno
	bit pndg;			//Bandera de vacio
	bit [pckg_sz-1:0] pile [$:pile_size-1];   
	
	//Inicializacion de las banderas
	function new();
		this.pndg = 0;
		this.fifo_full = 0;
	endfunction
	
	//Funcion de PUSH
  	function void push(bit [pckg_sz-1:0] mensaje, string tag = "");
      	//Verifica si se lleno el FIFO
      	if (pile.size() == pile_size) begin
			this.fifo_full = 1;
		end
      
		//Asercion si se hizo
		v_push: assert (!this.fifo_full) begin
          	$display("[Pass] PUSH cuando FIFO %s NO esta llena", tag);
		end else begin
          	$display("[Fail] PUSH cuando FIFO %s SI esta llena", tag);
		end
		
      	pile.push_front(mensaje);
		this.pndg = 1;
	endfunction
	
	//Funcion de POP
  	function bit[pckg_sz-1:0] pop(string tag = "");
		//Asercion de que no este vacio el FIFO
		v_pop: assert (pile.size() != 0) begin
          	$display("[Pass] POP cuando FIFO %s NO esta vacia", tag);
		end else begin
          	$display("[Fail] POP cuando FIFO %s SI esta vacia", tag);
		end	
		//Hace Pop el FIFO
		if(pile.size() > 0) begin
			if(pile.size() == 1) begin			
          		this.pndg = 0; 		
        	end
			return pile.pop_back;
		end
		
		this.fifo_full = 0;
	endfunction
	
  	//Funcion para saber si la cola esta vacia
  	function bit get_pndg();
      	if(pile.size() == 0) begin
          	this.pndg = 0;
        end
    	return this.pndg;
    endfunction;
  	
  	//Funcion para obtener tamaño de cola
  	function int get_size();
      return this.pile.size();
    endfunction;

endclass
	
	
	
	
	
	
	
	
	
	
	
	
	
