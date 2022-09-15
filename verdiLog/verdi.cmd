simSetSimulator "-vcssv" -exec "./salida" -args "+ntb_random_seed=2" -uvmDebug on \
           -simDelim
debImport "-i" "-simflow" "-dbdir" "./salida.daidir"
srcTBInvokeSim
debExit
