///////////////////////////////////////////////
//Definicion tipos posibles de transacciones 
///////////////////////////////////////////////
typedef enum {generico, broadcast, reset,uno_todo,todo_uno} tipo_trans;

///////////////////////////////////////////////////////////////////////////////////////////
//Paquete TransDUT (pck1) Agente/generador ---> Driver/Monitor y Diver/Monitor ---> Checker
///////////////////////////////////////////////////////////////////////////////////////////
class trans_dut ;
	int drvrs;
	int ancho;
	rand tipo_trans tipo;
	rand bit [64:0] dato; //-9 para los 8 bits que hay que concatenar de direccion
	rand bit [7:0] fuente;
	rand bit [7:0] destino;
	rand int retardo;
	int tiempo_envio;
	int tiempo_recibido;
	int max_retardo;	//Retardo maximo de 20

	constraint cons_dato{dato<163;}
	constraint const_retardo {retardo<max_retardo; retardo>0;}
	constraint const_destino {destino != fuente;destino inside{[0:drvrs-1]}; }/*destino<drvrs; destino>=0;}*/ 			 // Restriccion del destino 
	constraint const_fuente {fuente inside{[0:drvrs-1]};} //la fuente debe existir 

	function new (tipo_trans tpo = generico, bit dto =0 , bit [7:0] fte = 0 , bit [7:0] dstn=1, int ret=0, int t_envio=0,int t_recibido=0 , int max_ret=20);
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
class trans_sb;
	tipo_trans tipo;
	bit [64:0] dato_enviado;
	bit [7:0] Fuente;
	bit [7:0] Destino;
	int tiempo_envio;
	int tiempo_recibido;
	int retardo;
	int procedencia;
	int latencia;
	bit completado;
		
	function new();
		this.tipo = generico;
		this.dato_enviado=0;
		this.Fuente=0;
		this.Destino=0;
		this.tiempo_envio=0;
		this.tiempo_recibido=0;
		this.retardo=0;
		this.procedencia=0;
		this.latencia=0;
		this.completado=0;
		
	endfunction
	
	function clean();
		this.dato_enviado=0;
		this.Fuente=0;
		this.Destino=0;
		this.tiempo_envio=0;
		this.tiempo_recibido=0;
		this.latencia=0;
		this.completado=0;
	endfunction
	
	function calc_latencia();
		this.latencia=this.tiempo_recibido - this.tiempo_envio;
	endfunction
	
	function print(string tag); //Funcion para imprimir el contenido del objeto Trans_sb
		$display ("[%g] %s Tipo=%s Dato=0x%g Fuente_teorica=%g Destino_teorico=%g Procedencia=%g T_envio=%g T_recibido=%g Latencia=%g Completado=%g" , 
			$time,
			tag,
			this.tipo,
			this.dato_enviado,
			this.Fuente,
			this.Destino,
			this.procedencia,
			this.tiempo_envio,
			this.tiempo_recibido,
			this.latencia,
			this.completado
			);
		
		
	endfunction
endclass



///////////////////////////////////////////////
// Definicion de la transaccion pck4 Test-->Agente/Generador usando typedef 
///////////////////////////////////////////////
typedef enum {genericos, broadcast_inst , Rst_aleatorio, Completo, trans_especifica,uno_todos,todos_uno} instrucciones_agente; //completo es todo junto ***Se le cambio el nombre al broadcast porque ya habia uno igual***

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
	bit fifo_full;	//no hace falta
	bit pndg;			
	bit [pckg_sz-1:0] pile [$:pile_size-1];  //se crea de esta forma para acceder al primer dato con $  
	function new();
		this.pndg = 0;
		this.fifo_full = 0;
	endfunction
  	function void push(bit [pckg_sz-1:0] mensaje); //funcion para el push
      	if (pile.size() == pile_size) begin
			this.fifo_full = 1;
		end		
      	pile.push_front(mensaje);
		this.pndg = 1;
	endfunction
  	function bit[pckg_sz-1:0] pop(); //pop
		if(pile.size() > 0) begin
			if(pile.size() == 1) begin			
          		this.pndg = 0; 		
        	end
			return pile.pop_back;
		end
		this.fifo_full = 0;
	endfunction
  	function bit get_pndg(); //funcion pending
      	if(pile.size() == 0) begin
          	this.pndg = 0;
        end
    	return this.pndg;
    endfunction;
  	function int get_size();
      return this.pile.size();
    endfunction;

endclass
	
	
	
	
	
	
	
class interfaz_dispositivo #( parameter ancho=16,parameter drvrs=4,parameter Profundidad_fifo =10000000);
	virtual bus_if #(.drvrs(drvrs),.pckg_sz(ancho)) vif;
	trans_dut_mbx drv_fifos_mbx;
	trans_dut_mbx drv_chkr_mbx;
	trans_dut_mbx Simulado_driver_checker_mbx;
	fifo #(.pile_size(Profundidad_fifo), .pckg_sz(ancho)) drv_interfaz_fifo;
	fifo #(.pile_size(Profundidad_fifo), .pckg_sz(ancho)) fifo_salida;
	bit [ancho-1:0] paquete;
	bit [ancho-1:0] temporal;
	int delay;
	int dispositivo;

	task run();
		fifo_salida=new;
		drv_interfaz_fifo=new;
		//$display("	dispositivo creado[%g]",dispositivo);
		fork //Inicia los hijos para: Retardo, pop, revision de push y envio al checker
			begin//-------------------Inicia hijo para manejo de retardo------------------
				//Revisa el mailbox a ver si recibi?? una transaccion y la coloca en la fifo de entrada luego de haber simulado los ciclos de retardo correspondientes 
				//@(posedge vif.clk);
                forever begin
                	trans_dut transaccion =new();
					transaccion.ancho=ancho;
					transaccion.drvrs=drvrs;
                    delay = 0;  
                    @(posedge vif.clk);
                    drv_fifos_mbx.get(transaccion); //Saca la transaccion actual del mbx                          
					
					paquete[ancho-1:ancho-8] = transaccion.destino;
                    paquete[ancho-9:0] = transaccion.dato;
                  
    				//Ciclos de retraso
                    while(delay <= transaccion.retardo)begin
						if(transaccion.tipo==reset) vif.rst=1;  //Revisa si el tipo es reset para aplicarlo durante el retardo
                      	if(delay == transaccion.retardo)begin //Cuando se completa el retardo
							vif.rst=0;
                            drv_interfaz_fifo.push(paquete); // se coloca el dato en la fifo de entrada 
							transaccion.tiempo_envio=$time;
							Simulado_driver_checker_mbx.put(transaccion);
							transaccion.print("		Colocada en para el checker");
                            break;  
      					end
                        @(posedge vif.clk);
                        delay =  delay + 1;
    				end
                end
			end//-------------------Termina hijo manejo de retardo------------------
			
			
			
			begin//*****************Hijos para manejo de pop*************************
				//Revisa siempre si la bandera de pop del dut se activa y el caso que asi sea hace pop en la fifo simulada colocando en el bus Dpop el valor que tiene la fifo simulada en la salida
				forever begin
					@(posedge vif.clk);                                       
					if(vif.pop[0][dispositivo])begin
						vif.D_pop[0][dispositivo] = drv_interfaz_fifo.pop();
					  	vif.pndng[0][dispositivo] <= drv_interfaz_fifo.get_pndg();
					end else begin
					  	vif.D_pop[0][dispositivo] <= drv_interfaz_fifo.pile[$]; 
					end
					//manejo de bandera de pndng
					if(drv_interfaz_fifo.get_pndg() == 1) begin
					  	vif.pndng[0][dispositivo] <= 1;
					end else begin
					  	vif.pndng[0][dispositivo] <= 0;
					end
				end
			end// *****************Termina hijo manejos de pop****************************
			
			
			
			begin// +++++++++++++++++++Hijo manejo de push (Monitor)+++++++++++++++++++
				//Se mantiene siempre revisando si se recibe una transaccion y en caso que se reciba se guarda en la fifo simulada de salida
				@(posedge vif.clk);
				forever begin                 
				  	@(vif.push[0][dispositivo]); //Espera a recibir un push
					//$display("		Push=1");
				  	//PUSH a la fifo del dato recibido del dut
					  	fifo_salida.push(vif.D_push[0][dispositivo]);
						@(posedge vif.clk);
						@(posedge vif.clk);
				end
			end// +++++++++++++++++++Termina Hijo manejo de push (Monitor)+++++++++++
			
			begin//----------------Inicia hijo que maneja el envio al checker-----------------------
				//Se mantiene siempre revisando si en la fifo de salida se encuentran datos para ir sacandolos y enviandolos al mailbox del checker
				@(posedge vif.clk);
				forever begin
					trans_dut trans_recibida=new();
					trans_recibida.ancho=ancho;
					trans_recibida.drvrs=drvrs;
				  	@(posedge vif.clk);
					if(fifo_salida.get_pndg())begin
					  	temporal = fifo_salida.pop();  //Recibe de la fifo de salida el destino + dato  
						trans_recibida.destino=temporal[ancho-1:ancho-8];
						trans_recibida.dato = temporal[ancho-9:0];
						trans_recibida.tiempo_recibido = $time;
						trans_recibida.fuente = dispositivo;
						trans_recibida.print("		Driver: Se coloca transaccion para el checker");
				 		drv_chkr_mbx.put(trans_recibida);
						//$display("transacciones pendientes en mbx driver-checker = %g",drv_chkr_mbx.num()); //muestra todas las instrucciones pendientes en el mbx agnt-driver
					end
				end 
						
			end//----------Termina hijo que maneja el envio al checker-----------------------
	
		join_none	
	endtask
endclass 
	

















	
	
	
	
	
	
	
	
