class c_2_2;
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

program p_2_2;
    c_2_2 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "11z1xxxx10z1xxz10xx1xz1zz1x1001xzxzzzzzxxzxzzzzzzxzxzxxxxxzxzzzz";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
