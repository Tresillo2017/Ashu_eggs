#!/bin/bash
if [ -z "${PANEL}" ]; then
    GITHUB_PACKAGE=Jexactyl-Brasil/Jexactyl-Brasil
    FILE=panel.tar.gz
else
    if [ "${PANEL}" = "Pterodactyl" ]; then
        GITHUB_PACKAGE=pterodactyl/panel
        FILE=panel.tar.gz
    fi
    if [ "${PANEL}" = "Jexactyl" ]; then
        GITHUB_PACKAGE=Jexactyl/Jexactyl
        FILE=panel.tar.gz
    fi
    if [ "${PANEL}" = "Jexactyl Brasil" ]; then
        GITHUB_PACKAGE=Jexactyl-Brasil/Jexactyl-Brasil
        FILE=panel.tar.gz
    fi
fi

LATEST_JSON=$(curl --silent "https://api.github.com/repos/$GITHUB_PACKAGE/releases" | jq -c '.[]' | head -1)
RELEASES=$(curl --silent "https://api.github.com/repos/$GITHUB_PACKAGE/releases" | jq '.[]')

if [ -z "$VERSION" ] || [ "$VERSION" == "latest" ]; then
    DOWNLOAD_LINK=$(echo "$LATEST_JSON" | jq .assets | jq -r .[].browser_download_url | grep -i "$FILE")
else
    VERSION_CHECK=$(echo "$RELEASES" | jq -r --arg VERSION "$VERSION" '. | select(.tag_name==$VERSION) | .tag_name')
    if [ "$VERSION" == "$VERSION_CHECK" ]; then
        if [[ "$VERSION" == v* ]]; then
            DOWNLOAD_LINK=$(echo "$RELEASES" | jq -r --arg VERSION "$VERSION" '. | select(.tag_name==$VERSION) | .assets[].browser_download_url' | grep -i "$FILE")
        fi
    else
        DOWNLOAD_LINK=$(echo "$LATEST_JSON" | jq .assets | jq -r .[].browser_download_url | grep -i "$FILE")
    fi
fi
printf "\n \n📄  Verificando Instalação...\n \n"
printf "+----------+---------------------------------+\n| Tarefa   | Status                          |\n+----------+---------------------------------+"
if [ -d "/home/container/painel" ]; then
   printf "\n| Painel   | 🟢  Instalado                    |"
else
    cat <<EOF >./logs/log_install.txt
Versão: ${VERSION}
Git: ${GITHUB_PACKAGE}
Git_file: ${FILE}
Link: ${DOWNLOAD_LINK}
Arquivo: ${DOWNLOAD_LINK##*/}
EOF
    printf "\n| Painel   | 🟡 Baixando Painel               |"
    echo "**** Fazendo o download do painel ****"
    echo -e "running 'curl -sSL ${DOWNLOAD_LINK} -o ${DOWNLOAD_LINK##*/}'"
    curl -sSL "${DOWNLOAD_LINK}" -o "${DOWNLOAD_LINK##*/}"
    mkdir painel
    mv "${DOWNLOAD_LINK##*/}" painel
    cd painel
    echo -e "Unpacking server files"
    tar -xvzf "${DOWNLOAD_LINK##*/}"
    rm -rf "${DOWNLOAD_LINK##*/}"
    fakeroot chmod -R 755 storage/* bootstrap/cache/
    fakeroot chown -R nginx:nginx /home/container/painel/*
    cd ..
fi
git clone --quiet https://github.com/Ashu11-A/nginx ./temp
if [ -f "/home/container/nginx/nginx.conf" ]; then
 printf "\n| Nginx    | 🟢  Instalado                    |"
else
    printf "\n| Nginx    | 🟡  Baixando Nginx...            |"
    cp -r ./temp/nginx ./
    rm nginx/conf.d/default.conf
    curl -sSL https://raw.githubusercontent.com/Ashu11-A/Ashu_eggs/main/Paneldactyl/default.conf -o ./nginx/conf.d/default.conf
    sed -i \
        -e "s/listen.*/listen ${SERVER_PORT};/g" \
    nginx/conf.d/default.conf
fi
if [ -d "/home/container/php-fpm" ]; then
 printf "\n| PHP-FPM  | 🟢  Instalado                    |\n+----------+---------------------------------+\n"
else
    printf "\n| PHP-FPM  | 🟡  Baixando PHP-FPM...          |\n+----------+---------------------------------+\n"
    cp -r ./temp/php-fpm ./
        echo "extension=\"smbclient.so\"" >php-fpm/conf.d/00_smbclient.ini
        echo 'apc.enable_cli=1' >>php-fpm/conf.d/apcu.ini
        sed -i \
            -e 's/;opcache.enable.*=.*/opcache.enable=1/g' \
            -e 's/;opcache.interned_strings_buffer.*=.*/opcache.interned_strings_buffer=16/g' \
            -e 's/;opcache.max_accelerated_files.*=.*/opcache.max_accelerated_files=10000/g' \
            -e 's/;opcache.memory_consumption.*=.*/opcache.memory_consumption=128/g' \
            -e 's/;opcache.save_comments.*=.*/opcache.save_comments=1/g' \
            -e 's/;opcache.revalidate_freq.*=.*/opcache.revalidate_freq=1/g' \
            -e 's/;always_populate_raw_post_data.*=.*/always_populate_raw_post_data=-1/g' \
            -e 's/memory_limit.*=.*128M/memory_limit=512M/g' \
            -e 's/max_execution_time.*=.*30/max_execution_time=120/g' \
            -e 's/upload_max_filesize.*=.*2M/upload_max_filesize=1024M/g' \
            -e 's/post_max_size.*=.*8M/post_max_size=1024M/g' \
            -e 's/output_buffering.*=.*/output_buffering=0/g' \
            php-fpm/php.ini
        sed -i \
            '/opcache.enable=1/a opcache.enable_cli=1' \
            php-fpm/php.ini
        echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >>php-fpm/php-fpm.conf
fi
cp -r ./temp/logs ./
rm -rf /tmp/*
rm -rf ./temp
    if [ "${OCC}" == "1" ]; then
        cd painel || exit
        php "${COMMANDO_OCC}"
        exit
    else
        cd painel || exit
        if [[ -f ".env" ]]; then
            echo "| Env      | 🟢  Configurado                  |"
        else
            printf "\n \n⚙️  Executando: cp .env.example .env\n \n"
            cp .env.example .env
        fi
        if [[ -f "../logs/panel_composer_instalado" ]]; then
            echo "| Composer | 🟢  Instalado                    |"
        else
            printf "\n \n⚙️  Executando: composer install --no-interaction --no-dev --optimize-autoloader\n \n"
            composer install --no-interaction --no-dev --optimize-autoloader
            touch ../logs/panel_composer_instalado
        fi
        if [[ -f "../logs/panel_key_generate_instalado" ]]; then
            echo "| Key      | 🟢  Gerada                       |"
        else
            printf "\n \n⚙️  Executando: php artisan key:generate --force\n \n"
            php artisan key:generate --force
            touch ../logs/panel_key_generate_instalado
        fi

        if [[ -f "../logs/panel_setup_instalado" ]]; then
            echo "| Setup    | 🟢  Configurado                  |"
        else
            printf "\n \n⚙️  Executando: php artisan p:environment:setup\n \n"
            php artisan p:environment:setup
            touch ../logs/panel_setup_instalado
            printf "\n \n📌  Executar o comando anterior novamente? [y/N]\n \n"
            read -r response
            case "$response" in
            [yY][eE][sS] | [yY])
                php artisan p:environment:setup
                ;;
            *)
            esac
        fi
        if [[ -f "../logs/panel_database_instalado" ]]; then
            echo "| Database | 🟢  Configurado                  |"
        else
            printf "\n \n⚙️  Executando: php artisan p:environment:database\n \n"
            php artisan p:environment:database
            touch ../logs/panel_database_instalado
            printf "\n \n📌  Executar o comando anterior novamente? [y/N]\n \n"
            read -r response
            case "$response" in
            [yY][eE][sS] | [yY])
                php artisan p:environment:database
                ;;
            *)
                printf "\n \n⚙️  Executando: php artisan migrate --seed --force\n \n"
                ;;
            esac
        fi
        if [[ -f "../logs/panel_database_migrate_instalado" ]]; then
            echo "| Migração | 🟢  Concluído                    |"
        else
            php artisan migrate --seed --force
            touch ../logs/panel_database_migrate_instalado
            printf "\n \n📌  Executar o comando anterior novamente? [y/N]\n \n"
            read -r response
            case "$response" in
            [yY][eE][sS] | [yY])
                php artisan migrate --seed --force
                ;;
            *)
            esac
        fi
        if [[ -f "../logs/panel_user_instalado" ]]; then
            echo "| Usuário  | 🟢  Criado                       |"
        else
            printf "\n \n⚙️  Executando: php artisan p:user:make\n \n"
            php artisan p:user:make
            touch ../logs/panel_user_instalado
            printf "\n \n📌  Executar o comando anterior novamente? [y/N]\n \n"
            read -r response
            case "$response" in
            [yY][eE][sS] | [yY])
                php artisan p:user:make
                ;;
            *)
            esac
        fi
        cd ..
        if [[ -f "./logs/panel_instalado" ]]; then
            echo "+----------+---------------------------------+"
            printf "\n \n📑  Verificação do Painel Concluída...\n \n"
        else
            printf "\n \n⚙️  Executando: Atribuição de permissões\n \n"
            fakeroot chown -R nginx:nginx /home/container/painel/*
            printf "\n \n⚙️  Instalação do painel concluída\n \n"
            touch ./logs/panel_instalado
        fi
    fi
    if [[ -f "./logs/panel_instalado" ]]; then
        bash <(curl -s https://raw.githubusercontent.com/Ashu11-A/Ashu_eggs/main/Paneldactyl/version.sh)
        bash <(curl -s https://raw.githubusercontent.com/Ashu11-A/Ashu_eggs/main/Paneldactyl/launch.sh)
    fi
fi
