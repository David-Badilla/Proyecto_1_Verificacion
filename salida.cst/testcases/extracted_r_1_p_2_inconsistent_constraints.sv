class c_1_2;
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

program p_1_2;
    c_1_2 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "z010z10x1011zxx1xz0zz1z0xxz11z0xxxzxzxxzzzxxzxxzzxxxxzzxzzzxzxzz";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
