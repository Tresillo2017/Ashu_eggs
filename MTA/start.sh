#!/bin/bash
ARCH=$([ "$(uname -m)" == "x86_64" ] && echo "amd64" || echo "arm64")

if [ "${ARCH}" == "amd64" ];
then
    echo "🔎 Arquitetura Identificada: 64x"
    if [[ -f "./mta-server64" ]]; then
        echo "⚙️ Versão do Script: 1.4"
        echo "✅ Iniciando MTA"
        ./mta-server64 --maxplayers ${MAX_PLAYERS} -n --port ${SERVER_PORT} --httpport ${PORT_WEB}
    else
        echo "MTA Não Instalado, isso é realmente muito estranho, essa é uma segunda verificação."
    fi
else
    echo "🔎 Arquitetura Identificada: ARM64"
    echo "⚠️ Atenção: Este Egg ainda não funciona no ARM64"
    if [[ -f "./mta-server64" ]]; then
        echo "⚙️ Versão do Script: 1.4"
        echo "✅ Iniciando MTA"
        ./mta-server64 --maxplayers ${MAX_PLAYERS} -n --port ${SERVER_PORT} --httpport ${PORT_WEB}
    else
        echo "MTA Não Instalado, isso é realmente muito estranho, essa é uma segunda verificação."
    fi
fi