# !/bin/bash
echo "installing porcupine"
cp libpv_porcupine.so /usr/lib
cp {porcupine_demo_shm,porcupine_send_shm} /usr/bin
cp -R porcupine /usr/share/
echo "installed porcupine; WARNING: Currently doesnt work properly"
