#!/bin/bash
if [ "${FRP_MODE}" == "1" ]; then
    echo "⚙️ Versão do Script: 1.6"
    echo "👀 Saiba Mais: https://github.com/fatedier/frp"
    echo "✅ Iniciando Frps"
    cp -f ./Frpc/frpc.ini ./exemplo_frpc_windows64/frpc.ini
    ./Frps/frps -c ./Frps/frps.ini
else
    echo "⚙️ Versão do Script: 1.6"
    echo "👀 Saiba Mais: https://github.com/fatedier/frp"
    echo "✅ Iniciando Frpc"
    cp -f ./Frpc/frpc.ini ./exemplo_frpc_windows64/frpc.ini
    ./Frpc/frpc -c ./Frpc/frpc.ini
fi