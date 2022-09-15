class checkr #(parameter drvrs = 5, parameter ancho = 16);
    trans_dut #(.ancho(ancho),.drvrs(drvrs)) transaccion;
	trans_dut #(.ancho(ancho),.drvrs(drvrs)) transaccionemul;
    trans_dut #(.ancho(ancho),.drvrs(drvrs)) dut_emulado; //para enviar paquetes de la transaccion emulada que debe hacer el checker del dut
    trans_sb #(.ancho(ancho)) to_sb;
    trans_dut #(.ancho(ancho),.drvrs(drvrs)) emul_dut[$];
    

	trans_dut_mbx drv_chkr_mbx; //puntero del mailboxer no inicializado aun
    trans_sb_mbx chkr_sb_mbx; //puntero del mail boxer no inicializado aun
	trans_dut_mbx agente_checker_mbx;
    int cont;
    bit listo=0;
    function new();
        this.emul_dut = {};
        this.cont = 0;
    endfunction
    
    task run;
        $display("[%g] El checker fue inicializado",$time);
        to_sb = new();
		dut_emulado=new();
		transaccion=new();
		transaccionemul=new();
	fork
		begin
        forever begin
            to_sb = new();
			
            drv_chkr_mbx.get(transaccion); //Obtiene la transaccion de datos en el puntero que va de driver a checker
            transaccion.print("Checker: La transaccion ha sido recibida");
            to_sb.clean();
            case(transaccion.tipo)
                generico:begin
                        
						if(emul_dut.size()>0)begin
							//dut_emulado = emul_dut.pop_back();
							listo=0;//variable constrol para ver si se encuentra en la cola o no
							for (int i=0;i<emul_dut.size();i++) begin
				                if (transaccion.dato  == emul_dut[i].dato && transaccion.destino==emul_dut[i].destino)begin
									listo=1;//indica que ya se encontro la transaccion
									dut_emulado =emul_dut[i];
									emul_dut.delete(i); //borra el lugar en la cola para no volver a repetirlo
									to_sb.tipo = dut_emulado.tipo;
				                    to_sb.dato_enviado = dut_emulado.dato;
				                    to_sb.Fuente = dut_emulado.fuente;
									to_sb.retardo=dut_emulado.retardo;
									to_sb.procedencia=transaccion.fuente;
				                    to_sb.Destino = transaccion.destino;
				                    to_sb.tiempo_envio = dut_emulado.tiempo_envio;
				                    to_sb.tiempo_recibido = transaccion.tiempo_recibido;
									to_sb.calc_latencia();
									to_sb.completado=1;
				                    
				                    to_sb.print("Checker: Transaccion completada **ENVIADA AL SCOREBOARD**");
				                    chkr_sb_mbx.put(to_sb); //para poner en mailbox la info de to_sb
								end

							end
					             
						if(listo==0) begin
							transaccion.print("Dato que se transmite no calza con el esperado");
//		                    $display("Esperado %h, Leido %h", transaccion.dato, dut_emulado.dato);
						end
					end 
				end
					uno_todos:begin
						if(emul_dut.size()>0)begin
							//dut_emulado = emul_dut.pop_back();
							listo=0;//variable constrol para ver si se encuentra en la cola o no
							for (int i=0;i<emul_dut.size();i++) begin
				                if (transaccion.dato  == emul_dut[i].dato && transaccion.destino==emul_dut[i].destino)begin
									listo=1;//indica que ya se encontro la transaccion
									dut_emulado =emul_dut[i];
									emul_dut.delete(i); //borra el lugar en la cola para no volver a repetirlo
									to_sb.tipo = dut_emulado.tipo;
				                    to_sb.dato_enviado = dut_emulado.dato;
				                    to_sb.Fuente = dut_emulado.fuente;
									to_sb.retardo=dut_emulado.retardo;
									to_sb.procedencia=transaccion.fuente;
				                    to_sb.Destino = transaccion.destino;
				                    to_sb.tiempo_envio = dut_emulado.tiempo_envio;
				                    to_sb.tiempo_recibido = transaccion.tiempo_recibido;
									to_sb.calc_latencia();
									to_sb.completado=1;
				                    
				                    to_sb.print("Checker: Transaccion completada **ENVIADA AL SCOREBOARD**");
				                    chkr_sb_mbx.put(to_sb); //para poner en mailbox la info de to_sb
								end

							end
					             
						if(listo==0) begin
							transaccion.print("Dato que se transmite no calza con el esperado");
//		                    $display("Esperado %h, Leido %h", transaccion.dato, dut_emulado.dato);
						end
					end
				end
					todos_uno:begin
						if(emul_dut.size()>0)begin
							//dut_emulado = emul_dut.pop_back();
							listo=0;//variable constrol para ver si se encuentra en la cola o no
							for (int i=0;i<emul_dut.size();i++) begin
				                if (transaccion.dato  == emul_dut[i].dato && transaccion.destino==emul_dut[i].destino)begin
									listo=1;//indica que ya se encontro la transaccion
									dut_emulado =emul_dut[i];
									emul_dut.delete(i); //borra el lugar en la cola para no volver a repetirlo
									to_sb.tipo = dut_emulado.tipo;
				                    to_sb.dato_enviado = dut_emulado.dato;
				                    to_sb.Fuente = dut_emulado.fuente;
									to_sb.retardo=dut_emulado.retardo;
									to_sb.procedencia=transaccion.fuente;
				                    to_sb.Destino = transaccion.destino;
				                    to_sb.tiempo_envio = dut_emulado.tiempo_envio;
				                    to_sb.tiempo_recibido = transaccion.tiempo_recibido;
									to_sb.calc_latencia();
									to_sb.completado=1;
				                    
				                    to_sb.print("Checker: Transaccion completada **ENVIADA AL SCOREBOARD**");
				                    chkr_sb_mbx.put(to_sb); //para poner en mailbox la info de to_sb
								end

							end
					             
						if(listo==0) begin
							transaccion.print("Dato que se transmite no calza con el esperado");
//		                    $display("Esperado %h, Leido %h", transaccion.dato, dut_emulado.dato);
						end
					end 
					end
					reset:begin
						if(emul_dut.size()>0)begin
							//dut_emulado = emul_dut.pop_back();
							listo=0;//variable constrol para ver si se encuentra en la cola o no
							for (int i=0;i<emul_dut.size();i++) begin
				                if (transaccion.dato  == emul_dut[i].dato && transaccion.destino==emul_dut[i].destino)begin
									listo=1;//indica que ya se encontro la transaccion
									dut_emulado =emul_dut[i];
									emul_dut.delete(i); //borra el lugar en la cola para no volver a repetirlo
									to_sb.tipo = dut_emulado.tipo;
				                    to_sb.dato_enviado = dut_emulado.dato;
				                    to_sb.Fuente = dut_emulado.fuente;
									to_sb.retardo=dut_emulado.retardo;
									to_sb.procedencia=transaccion.fuente;
				                    to_sb.Destino = transaccion.destino;
				                    to_sb.tiempo_envio = dut_emulado.tiempo_envio;
				                    to_sb.tiempo_recibido = transaccion.tiempo_recibido;
									to_sb.calc_latencia();
									to_sb.completado=1;
				                    
				                    to_sb.print("Checker: Transaccion completada **ENVIADA AL SCOREBOARD**");
				                    chkr_sb_mbx.put(to_sb); //para poner en mailbox la info de to_sb
								end

							end
					     end        
						if(listo==0) begin
							transaccion.print("Dato que se transmite no calza con el esperado");
//		                    $display("Esperado %h, Leido %h", transaccion.dato, dut_emulado.dato);
						end

					end
                 
            endcase      
        	end
		end
	begin
		forever begin
			agente_checker_mbx.get(transaccionemul);
			transaccionemul.print("Check - agente Recibido");
			emul_dut.push_back(transaccionemul);
		end
	end
	join_none
    endtask      
endclass
