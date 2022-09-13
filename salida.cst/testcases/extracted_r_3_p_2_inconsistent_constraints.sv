class c_3_2;
    rand bit[7:0] destino; // rand_mode = ON 
    rand bit[7:0] fuente; // rand_mode = ON 

    constraint const_destino_this    // (constraint_mode = ON) (paquetes.sv:20)
    {
       (destino != fuente);
       (destino < 8'h1);
    }
    constraint const_fuente_this    // (constraint_mode = ON) (paquetes.sv:21)
    {
       (fuente < 8'h1);
    }
endclass

program p_3_2;
    c_3_2 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "1z11010100111zx0x0x1z11x11z000x1xxzzxzzxzxxzzxzzxzxxxzxxxzzzxzxz";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
