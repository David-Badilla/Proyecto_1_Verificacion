class checkr #(parameter drvrs = 4, parameter ancho = 16);
    trans_dut #(.ancho(ancho)) transaccion;
    trans_dut #(.ancho(ancho)) dut_emulado; //para enviar paquetes de la transaccion emulada que debe hacer el checker del dut
    trans_sb #(.ancho(ancho)) to_sb;
    trans_dut emul_dut[$];
    trans_dut_mbx drv_chkr_mbx; //puntero del mailboxer no inicializado aun
    trans_sb_mbx chkr_sb_mbx; //puntero del mail boxer no inicializado aun
    int cont;
    
    function new();
        this.emul_dut = {};
        this.cont = 0;
    endfunction
    
    task run;
        $display("[%g] El checker fue inicializado",$time);
        to_sb = new();
        forever begin
            to_sb = new();
            drv_chkr_mbx.get(transaccion); //Obtiene la transaccion de datos en el puntero que va de driver a checker
            transaccion.print("La transaccion ha sido recibida");
            to_sb.clean();
            case(transaccion.tipo)
                generico:begin
                        dut_emulado = emul_dut.pop_front();
                        if (transaccion.dato == dut_emulado.dato)begin
                            to_sb.dato_enviado = dut_emulado.dato_enviado;
                            to_sb.Fuente = dut_emulado.Fuente;
                            to_sb.Destino = dut_emulado.Destino;
                            to_sb.tiempo_envio = dut_emulado.tiempo_envio;
                            to_sb.tiempo_recibido = dut_emulado.tiempo_recibido;
                            to_sb.latencia = dut_emulado.latencia;
                            to_sb.print("Transaccion completada");
                            chkr_sb_mbx.put(to_sb); //para poner en mailbox la info de to_sb
                        end else begin
                            transaccion.print("Dato que se transmite no calza con el esperado");
                            $display("Esperado %h, Leido %h", transaccion.dato, dut_emulado.dato);
                        end              
                end  
            endcase      
        end
    endtask      
endclass
