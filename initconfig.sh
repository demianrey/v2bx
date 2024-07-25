#!/bin/bash
# 一键配置

# 检查系统是否有 IPv6 地址
check_ipv6_support() {
    if ip -6 addr | grep -q "inet6"; then
        echo "1"  # 支持 IPv6
    else
        echo "0"  # 不支持 IPv6
    fi
}

add_node_config() {
    echo -e "${green}Seleccione un tipo de núcleo de nodo:${plain}"
    echo -e "${green}1. xray${plain}"
    echo -e "${green}2. singbox${plain}"
    echo -e "${green}3. hysteria2${plain}"
    read -rp "por favor seleccione:" core_type
    if [ "$core_type" == "1" ]; then
        core="xray"
        core_xray=true
    elif [ "$core_type" == "2" ]; then
        core="sing"
        core_sing=true
    elif [ "$core_type" == "3" ]; then
        core="hysteria2"
        core_hysteria2=true
    else
        echo "Selección invalida. Por favor seleccione 1 2 3."
        continue
    fi
    while true; do
        read -rp "Por favor ingrese el ID del nodo:" NodeID
        # 判断NodeID是否为正整数
        if [[ "$NodeID" =~ ^[0-9]+$ ]]; then
            break  # 输入正确，退出循环
        else
            echo "Error: ingrese el número correcto del ID de nodo."
        fi
    done

    if [ "$core_hysteria2" = true ] && [ "$core_xray" = false ] && [ "$core_sing" = false ]; then
        NodeType="hysteria2"
    else
        echo -e "${yellow}Seleccione un protocolo de transporte:${plain}"
        echo -e "${green}1. Shadowsocks${plain}"
        echo -e "${green}2. Vless${plain}"
        echo -e "${green}3. Vmess${plain}"
        if [ "$core_sing" == true ]; then
            echo -e "${green}4. Hysteria${plain}"
            echo -e "${green}5. Hysteria2${plain}"
        fi
        if [ "$core_hysteria2" == true ] && [ "$core_sing" = false ]; then
            echo -e "${green}5. Hysteria2${plain}"
        fi
        echo -e "${green}6. Trojan${plain}"  
        read -rp "por favor seleccione:" NodeType
        case "$NodeType" in
            1 ) NodeType="shadowsocks" ;;
            2 ) NodeType="vless" ;;
            3 ) NodeType="vmess" ;;
            4 ) NodeType="hysteria" ;;
            5 ) NodeType="hysteria2" ;;
            6 ) NodeType="trojan" ;;
            * ) NodeType="shadowsocks" ;;
        esac
    fi
    if [ $NodeType == "vless" ]; then
        read -rp "Seleccione si es un nodo de reality.(y/n)" isreality
    fi
    certmode="none"
    certdomain="example.com"
    if [ "$isreality" != "y" ] && [ "$isreality" != "Y" ]; then
        read -rp "¿Elija si desea configurar TLS?(y/n)" istls
        if [ "$istls" == "y" ] || [ "$istls" == "Y" ]; then
            echo -e "${yellow}Por favor seleccione el modo del certificado:${plain}"
            echo -e "${green}1. [http]Aplicación automática en modo http, el nombre de dominio del nodo se ha resuelto correctamente${plain}"
            echo -e "${green}2. [dns]Aplicación automática en modo dns, debe completar los parámetros API del proveedor de servicios${plain}"
            echo -e "${green}3. [self]Modo autónomo, autofirmar el certificado o proporcionar un archivo de certificado existente${plain}"
            read -rp "por favor seleccione:" certmode
            case "$certmode" in
                1 ) certmode="http" ;;
                2 ) certmode="dns" ;;
                3 ) certmode="self" ;;
            esac
            read -rp "Por favor ingrese el nombre de dominio (example.com)]：" certdomain
            if [ $certmode != "http" ]; then
                echo -e "${red}Modifique manualmente el archivo de configuración y reinicie V2bX.${plain}"
            fi
        fi
    fi
    ipv6_support=$(check_ipv6_support)
    listen_ip="0.0.0.0"
    if [ "$ipv6_support" -eq 1 ]; then
        listen_ip="::"
    fi
    node_config=""
    if [ "$core_type" == "1" ]; then 
    node_config=$(cat <<EOF
{
            "Core": "$core",
            "ApiHost": "$ApiHost",
            "ApiKey": "$ApiKey",
            "NodeID": $NodeID,
            "NodeType": "$NodeType",
            "Timeout": 30,
            "ListenIP": "0.0.0.0",
            "SendIP": "0.0.0.0",
            "DeviceOnlineMinTraffic": 1000,
            "EnableProxyProtocol": false,
            "EnableUot": true,
            "EnableTFO": true,
            "DNSType": "UseIPv4",
            "CertConfig": {
                "CertMode": "$certmode",
                "RejectUnknownSni": false,
                "CertDomain": "$certdomain",
                "CertFile": "/etc/V2bX/fullchain.cer",
                "KeyFile": "/etc/V2bX/cert.key",
                "Email": "v2bx@github.com",
                "Provider": "cloudflare",
                "DNSEnv": {
                    "EnvName": "env1"
                }
            }
        },
EOF
)
    elif [ "$core_type" == "2" ]; then
    node_config=$(cat <<EOF
{
            "Core": "$core",
            "ApiHost": "$ApiHost",
            "ApiKey": "$ApiKey",
            "NodeID": $NodeID,
            "NodeType": "$NodeType",
            "Timeout": 30,
            "ListenIP": "$listen_ip",
            "SendIP": "0.0.0.0",
            "DeviceOnlineMinTraffic": 1000,
            "TCPFastOpen": true,
            "SniffEnabled": true,
            "EnableDNS": true,
            "CertConfig": {
                "CertMode": "$certmode",
                "RejectUnknownSni": false,
                "CertDomain": "$certdomain",
                "CertFile": "/etc/V2bX/fullchain.cer",
                "KeyFile": "/etc/V2bX/cert.key",
                "Email": "v2bx@github.com",
                "Provider": "cloudflare",
                "DNSEnv": {
                    "EnvName": "env1"
                }
            }
        },
EOF
)
    elif [ "$core_type" == "3" ]; then
    node_config=$(cat <<EOF
{
            "Core": "$core",
            "ApiHost": "$ApiHost",
            "ApiKey": "$ApiKey",
            "NodeID": $NodeID,
            "NodeType": "$NodeType",
            "Hysteria2ConfigPath": "/etc/V2bX/hy2config.yaml",
            "Timeout": 30,
            "ListenIP": "",
            "SendIP": "0.0.0.0",
            "DeviceOnlineMinTraffic": 1000,
            "CertConfig": {
                "CertMode": "$certmode",
                "RejectUnknownSni": false,
                "CertDomain": "$certdomain",
                "CertFile": "/etc/V2bX/fullchain.cer",
                "KeyFile": "/etc/V2bX/cert.key",
                "Email": "v2bx@github.com",
                "Provider": "cloudflare",
                "DNSEnv": {
                    "EnvName": "env1"
                }
            }
        },
EOF
)
    fi
    nodes_config+=("$node_config")
}

generate_config_file() {
    echo -e "${yellow}V2bX Asistente de generación de archivos de configuración${plain}"
    echo -e "${red}Por favor lea las siguientes notas:${plain}"
    echo -e "${red}1. Esta característica se encuentra actualmente en la fase de prueba.${plain}"
    echo -e "${red}2. El archivo de configuración generado se guardará en /etc/V2bX/config.json${plain}"
    echo -e "${red}3. El archivo de configuración original se guardará en /etc/V2bX/config.json.bak${plain}"
    echo -e "${red}4. Actualmente, TLS solo es compatible parcialmente${plain}"
    echo -e "${red}5. El archivo de configuración generado usando esta función vendrá con su propia auditoría. ¿Está seguro de que desea continuar?(y/n)${plain}"
    read -rp "por favor seleccione:" continue_prompt
    if [[ "$continue_prompt" =~ ^[Nn][Oo]? ]]; then
        exit 0
    fi
    
    nodes_config=()
    first_node=true
    core_xray=false
    core_sing=false
    core_hysteria2=false
    fixed_api_info=false
    check_api=false
    
    while true; do
        if [ "$first_node" = true ]; then
            read -rp "Por favor introduzca la dirección del panel:" ApiHost
            read -rp "Ingrese la clave API de comunicación del panel：" ApiKey
            read -rp "¿Quiere establecer una URL de aeropuerto fija y una clave API?(y/n)" fixed_api
            if [ "$fixed_api" = "y" ] || [ "$fixed_api" = "Y" ]; then
                fixed_api_info=true
                echo -e "${red}Dirección fijada con éxito${plain}"
            fi
            first_node=false
            add_node_config
        else
            read -rp "¿Quieres seguir añadiendo configuración de nodos? (Presione enter para continuar, ingrese n o no para salir)" continue_adding_node
            if [[ "$continue_adding_node" =~ ^[Nn][Oo]? ]]; then
                break
            elif [ "$fixed_api_info" = false ]; then
                read -rp "Por favor introduzca la dirección del panel(https://example.com)：" ApiHost
                read -rp "Ingrese la clave API de comunicación del panel:" ApiKey
            fi
            add_node_config
        fi
    done

    # 初始化核心配置数组
    cores_config="["

    # 检查并添加xray核心配置
    if [ "$core_xray" = true ]; then
        cores_config+="
    {
        \"Type\": \"xray\",
        \"Log\": {
            \"Level\": \"error\",
            \"ErrorPath\": \"/etc/V2bX/error.log\"
        },
        \"OutboundConfigPath\": \"/etc/V2bX/custom_outbound.json\",
        \"RouteConfigPath\": \"/etc/V2bX/route.json\"
    },"
    fi

    # 检查并添加sing核心配置
    if [ "$core_sing" = true ]; then
        cores_config+="
    {
        \"Type\": \"sing\",
        \"Log\": {
            \"Level\": \"error\",
            \"Timestamp\": true
        },
        \"NTP\": {
            \"Enable\": false,
            \"Server\": \"time.apple.com\",
            \"ServerPort\": 0
        },
        \"OriginalPath\": \"/etc/V2bX/sing_origin.json\"
    },"
    fi

    # 检查并添加hysteria2核心配置
    if [ "$core_hysteria2" = true ]; then
        cores_config+="
    {
        \"Type\": \"hysteria2\",
        \"Log\": {
            \"Level\": \"error\"
        }
    },"
    fi

    # 移除最后一个逗号并关闭数组
    cores_config+="]"
    cores_config=$(echo "$cores_config" | sed 's/},]$/}]/')

    # 切换到配置文件目录
    cd /etc/V2bX
    
    # 备份旧的配置文件
    mv config.json config.json.bak
    nodes_config_str="${nodes_config[*]}"
    formatted_nodes_config="${nodes_config_str%,}"

    # 创建 config.json 文件
    cat <<EOF > /etc/V2bX/config.json
{
    "Log": {
        "Level": "error",
        "Output": ""
    },
    "Cores": $cores_config,
    "Nodes": [$formatted_nodes_config]
}
EOF
    
    # 创建 custom_outbound.json 文件
    cat <<EOF > /etc/V2bX/custom_outbound.json
    [
        {
            "tag": "IPv4_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv4v6"
            }
        },
        {
            "tag": "IPv6_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv6"
            }
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
EOF
    
    # 创建 route.json 文件
    cat <<EOF > /etc/V2bX/route.json
    {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "outboundTag": "block",
                "ip": [
                    "geoip:private",
                    "geoip:cn"
                ]
            },
            {
                "domain": [
                    "geosite:google"
                ],
                "outboundTag": "IPv4_out",
                "type": "field"
            },
            {
                "type": "field",
                "outboundTag": "block",
                "domain": [
                    "geosite:cn"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "domain": [
                    "regexp:(api|ps|sv|offnavi|newvector|ulog.imap|newloc)(.map|).(baidu|n.shifen).com",
                    "regexp:(.+.|^)(360|so).(cn|com)",
                    "regexp:(Subject|HELO|SMTP)",
                    "regexp:(torrent|.torrent|peer_id=|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=)",
                    "regexp:(^.@)(guerrillamail|guerrillamailblock|sharklasers|grr|pokemail|spam4|bccto|chacuo|027168).(info|biz|com|de|net|org|me|la)",
                    "regexp:(.?)(xunlei|sandai|Thunder|XLLiveUD)(.)",
                    "regexp:(..||)(dafahao|mingjinglive|botanwang|minghui|dongtaiwang|falunaz|epochtimes|ntdtv|falundafa|falungong|wujieliulan|zhengjian).(org|com|net)",
                    "regexp:(ed2k|.torrent|peer_id=|announce|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=|magnet:|xunlei|sandai|Thunder|XLLiveUD|bt_key)",
                    "regexp:(.+.|^)(360).(cn|com|net)",
                    "regexp:(.*.||)(guanjia.qq.com|qqpcmgr|QQPCMGR)",
                    "regexp:(.*.||)(rising|kingsoft|duba|xindubawukong|jinshanduba).(com|net|org)",
                    "regexp:(.*.||)(netvigator|torproject).(com|cn|net|org)",
                    "regexp:(..||)(visa|mycard|gash|beanfun|bank).",
                    "regexp:(.*.||)(gov|12377|12315|talk.news.pts.org|creaders|zhuichaguoji|efcc.org|cyberpolice|aboluowang|tuidang|epochtimes|zhengjian|110.qq|mingjingnews|inmediahk|xinsheng|breakgfw|chengmingmag|jinpianwang|qi-gong|mhradio|edoors|renminbao|soundofhope|xizang-zhiye|bannedbook|ntdtv|12321|secretchina|dajiyuan|boxun|chinadigitaltimes|dwnews|huaglad|oneplusnews|epochweekly|cn.rfi).(cn|com|org|net|club|net|fr|tw|hk|eu|info|me)",
                    "regexp:(.*.||)(miaozhen|cnzz|talkingdata|umeng).(cn|com)",
                    "regexp:(.*.||)(mycard).(com|tw)",
                    "regexp:(.*.||)(gash).(com|tw)",
                    "regexp:(.bank.)",
                    "regexp:(.*.||)(pincong).(rocks)",
                    "regexp:(.*.||)(taobao).(com)",
                    "regexp:(.*.||)(laomoe|jiyou|ssss|lolicp|vv1234|0z|4321q|868123|ksweb|mm126).(com|cloud|fun|cn|gs|xyz|cc)",
                    "regexp:(flows|miaoko).(pages).(dev)"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "ip": [
                    "127.0.0.1/32",
                    "10.0.0.0/8",
                    "fc00::/7",
                    "fe80::/10",
                    "172.16.0.0/12"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "protocol": [
                    "bittorrent"
                ]
            }
        ]
    }
EOF

    # 创建 sing_origin.json 文件           
    cat <<EOF > /etc/V2bX/sing_origin.json
{
  "outbounds": [
    {
      "tag": "direct",
      "type": "direct",
      "domain_strategy": "prefer_ipv4"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ],
  "route": {
    "rules": [
      {
        "ip_is_private": true,
        "outbound": "block"
      },
      {
        "rule_set": [
          "geosite-google"
        ],
        "outbound": "direct"
      },
      {
        "rule_set": [
          "geosite-category-ads-all",
          "geosite-cn",
          "geoip-cn"
        ],
        "outbound": "block"
      },
      {
        "domain_regex": [
            "(api|ps|sv|offnavi|newvector|ulog.imap|newloc)(.map|).(baidu|n.shifen).com",
            "(.+.|^)(360|so).(cn|com)",
            "(Subject|HELO|SMTP)",
            "(torrent|.torrent|peer_id=|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=)",
            "(^.@)(guerrillamail|guerrillamailblock|sharklasers|grr|pokemail|spam4|bccto|chacuo|027168).(info|biz|com|de|net|org|me|la)",
            "(.?)(xunlei|sandai|Thunder|XLLiveUD)(.)",
            "(..||)(dafahao|mingjinglive|botanwang|minghui|dongtaiwang|falunaz|epochtimes|ntdtv|falundafa|falungong|wujieliulan|zhengjian).(org|com|net)",
            "(ed2k|.torrent|peer_id=|announce|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=|magnet:|xunlei|sandai|Thunder|XLLiveUD|bt_key)",
            "(.+.|^)(360).(cn|com|net)",
            "(.*.||)(guanjia.qq.com|qqpcmgr|QQPCMGR)",
            "(.*.||)(rising|kingsoft|duba|xindubawukong|jinshanduba).(com|net|org)",
            "(.*.||)(netvigator|torproject).(com|cn|net|org)",
            "(..||)(visa|mycard|gash|beanfun|bank).",
            "(.*.||)(gov|12377|12315|talk.news.pts.org|creaders|zhuichaguoji|efcc.org|cyberpolice|aboluowang|tuidang|epochtimes|zhengjian|110.qq|mingjingnews|inmediahk|xinsheng|breakgfw|chengmingmag|jinpianwang|qi-gong|mhradio|edoors|renminbao|soundofhope|xizang-zhiye|bannedbook|ntdtv|12321|secretchina|dajiyuan|boxun|chinadigitaltimes|dwnews|huaglad|oneplusnews|epochweekly|cn.rfi).(cn|com|org|net|club|net|fr|tw|hk|eu|info|me)",
            "(.*.||)(miaozhen|cnzz|talkingdata|umeng).(cn|com)",
            "(.*.||)(mycard).(com|tw)",
            "(.*.||)(gash).(com|tw)",
            "(.bank.)",
            "(.*.||)(pincong).(rocks)",
            "(.*.||)(taobao).(com)",
            "(.*.||)(laomoe|jiyou|ssss|lolicp|vv1234|0z|4321q|868123|ksweb|mm126).(com|cloud|fun|cn|gs|xyz|cc)",
            "(flows|miaoko).(pages).(dev)"
        ],
        "outbound": "block"
      },
      {
        "outbound": "direct",
        "network": [
          "udp","tcp"
        ]
      }
    ],
    "rule_set": [
      {
        "tag": "geoip-cn",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-cn",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-cn.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-category-ads-all",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-google",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-google.srs",
        "download_detour": "direct"
      }
    ]
  },
  "experimental": {
    "cache_file": {
      "enabled": true
    }
  }
}
EOF

    # 创建 hy2config.yaml 文件           
    cat <<EOF > /etc/V2bX/hy2config.yaml
quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 20971520
  maxConnReceiveWindow: 20971520
  maxIdleTimeout: 30s
  maxIncomingStreams: 1024
  disablePathMTUDiscovery: false
ignoreClientBandwidth: false
disableUDP: false
udpIdleTimeout: 60s
resolver:
  type: system
acl:
  inline:
    - direct(geosite:google)
    - reject(geosite:cn)
    - reject(geoip:cn)
masquerade:
  type: 404
EOF
    echo -e "${green}V2bX Se completo la generación del archivo de configuración y se reinicia el servicio.${plain}"
    v2bx restart
}

install_bbr() {
    bash <(curl -L -s https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh)
}
