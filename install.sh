#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}error:${plain} ¡Este script debe ejecutarse como root!\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "alpine"; then
    release="alpine"
    echo -e "${red}¡El script aún no es compatible con el sistema alpine!${plain}\n" && exit 1
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat|rocky|alma|oracle linux"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat|rocky|alma|oracle linux"; then
    release="centos"
else
    echo -e "${red}Versión del sistema no detectada, ¡comuníquese con el autor del script!${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64-v8a"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="64"
    echo -e "${red}No se pudo detectar la arquitectura, use la arquitectura predeterminada: ${arch}${plain}"
fi

echo "Arquitectura: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "Este software no es compatible con sistemas de 32 bits (x86), utilice sistemas de 64 bits (x86_64). Si la detección es incorrecta, comuníquese con el autor."
    exit 2
fi

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}¡Utilice CentOS 7 o superior!${plain}\n" && exit 1
    fi
    if [[ ${os_version} -eq 7 ]]; then
        echo -e "${red}Nota: ¡CentOS 7 no puede usar el protocolo histeria1/2!${plain}\n"
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}¡Utilice Ubuntu 16 o superior!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}¡Utilice Debian 8 o una versión superior del sistema!${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
        yum install wget curl unzip tar crontabs socat -y
        yum install ca-certificates wget -y
        update-ca-trust force-enable
    else
        apt-get update -y
        apt install wget curl unzip tar cron socat -y
        apt-get install ca-certificates wget -y
        update-ca-certificates
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/V2bX.service ]]; then
        return 2
    fi
    temp=$(systemctl status V2bX | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

install_V2bX() {
    if [[ -e /usr/local/V2bX/ ]]; then
        rm -rf /usr/local/V2bX/
    fi

    mkdir /usr/local/V2bX/ -p
    cd /usr/local/V2bX/

    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/wyx2685/V2bX/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}No se pudo detectar la versión V2bX. Es posible que se haya excedido el límite de la API de Github. Inténtelo de nuevo más tarde o especifique manualmente la versión V2bX para la instalación.${plain}"
            exit 1
        fi
        echo -e "Última versión de V2bX detectada:${last_version}, inicia la instalación"
        wget -q -N --no-check-certificate -O /usr/local/V2bX/V2bX-linux.zip https://github.com/wyx2685/V2bX/releases/download/${last_version}/V2bX-linux-${arch}.zip
        if [[ $? -ne 0 ]]; then
            echo -e "${red}No se pudo descargar V2bX, asegúrese de que su servidor pueda descargar archivos Github${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/wyx2685/V2bX/releases/download/${last_version}/V2bX-linux-${arch}.zip"
        echo -e "开始安装 V2bX $1"
        wget -q -N --no-check-certificate -O /usr/local/V2bX/V2bX-linux.zip ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Descargar V2bX $1 Error, asegúrese de que esta versión exista${plain}"
            exit 1
        fi
    fi

    unzip V2bX-linux.zip
    rm V2bX-linux.zip -f
    chmod +x V2bX
    mkdir /etc/V2bX/ -p
    rm /etc/systemd/system/V2bX.service -f
    file="https://github.com/wyx2685/V2bX-script/raw/master/V2bX.service"
    wget -q -N --no-check-certificate -O /etc/systemd/system/V2bX.service ${file}
    #cp -f V2bX.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl stop V2bX
    systemctl enable V2bX
    echo -e "${green}V2bX ${last_version}${plain} La instalación está completa y se ha configurado el inicio automático."
    cp geoip.dat /etc/V2bX/
    cp geosite.dat /etc/V2bX/

    if [[ ! -f /etc/V2bX/config.json ]]; then
        cp config.json /etc/V2bX/
        echo -e ""
        echo -e "Para una nueva instalación, consulte primero el tutorial: https://v2bx.v-50.me/ para configurar el contenido necesario."
        first_install=true
    else
        systemctl start V2bX
        sleep 2
        check_status
        echo -e ""
        if [[ $? == 0 ]]; then
            echo -e "${green}V2bX Reiniciado exitosamente${plain}"
        else
            echo -e "${red}Es posible que V2bX no se inicie. Utilice el registro de V2bX para ver la información del registro más adelante. Si no se inicia, es posible que se haya cambiado el formato de configuración. Vaya a la wiki para ver: https://github.com/V2bX-project. /V2bX/wiki${plain}"
        fi
        first_install=false
    fi

    if [[ ! -f /etc/V2bX/dns.json ]]; then
        cp dns.json /etc/V2bX/
    fi
    if [[ ! -f /etc/V2bX/route.json ]]; then
        cp route.json /etc/V2bX/
    fi
    if [[ ! -f /etc/V2bX/custom_outbound.json ]]; then
        cp custom_outbound.json /etc/V2bX/
    fi
    if [[ ! -f /etc/V2bX/custom_inbound.json ]]; then
        cp custom_inbound.json /etc/V2bX/
    fi
    curl -o /usr/bin/V2bX -Ls https://raw.githubusercontent.com/demianrey/v2bx/DR/V2bX.sh
    chmod +x /usr/bin/V2bX
    if [ ! -L /usr/bin/v2bx ]; then
        ln -s /usr/bin/V2bX /usr/bin/v2bx
        chmod +x /usr/bin/v2bx
    fi
    cd $cur_dir
    rm -f install.sh
    echo -e ""
    echo "V2bX comandos(V2bX, no distingue entre mayúsculas y minúsculas): "
    echo "------------------------------------------"
    echo "V2bX              - Mostrar menú de gestión (más funciones)"
    echo "V2bX start        - Iniciar V2bX"
    echo "V2bX stop         - Detener V2bX"
    echo "V2bX restart      - Reiniciar V2bX"
    echo "V2bX status       - Estado V2bX"
    echo "V2bX enable       - Habilitar V2bX"
    echo "V2bX disable      - Deshabilitar V2bX"
    echo "V2bX log          - Registro V2bX"
    echo "V2bX x25519       - Generar clave x25519"
    echo "V2bX generate     - Generar archivo de configuración V2bX"
    echo "V2bX update       - Actualizar V2bX"
    echo "V2bX update x.x.x - Actualizar V2bX version"
    echo "V2bX install      - Instalar V2bX"
    echo "V2bX uninstall    - Desinstalar V2bX"
    echo "V2bX version      - Version V2bX"
    echo "------------------------------------------"
    # 首次安装询问是否生成配置文件
    if [[ $first_install == true ]]; then
        read -rp "Se detecta que está instalando V2bX por primera vez. ¿Se generará automáticamente el archivo de configuración directamente? (y/n): " if_generate
        if [[ $if_generate == [Yy] ]]; then
            curl -o ./initconfig.sh -Ls https://raw.githubusercontent.com/demianrey/v2bx/DR/initconfig.sh
            source initconfig.sh
            rm initconfig.sh -f
            generate_config_file
        fi
    fi
}

echo -e "${green}Inicia la instalación${plain}"
install_base
install_V2bX $1
