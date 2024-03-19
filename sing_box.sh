#!/bin/bash

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
NC='\033[0m'

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "fedora")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Fedora")
PACKAGE_UPDATE=("apt-get update" "apt-get update" "yum -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "yum -y install")
PACKAGE_REMOVE=("apt -y remove" "apt -y remove" "yum -y remove" "yum -y remove" "yum -y remove")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove" "yum -y autoremove")

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
    SYS="$i"
    if [[ -n $SYS ]]; then
        break
    fi
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    if [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]]; then
        SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
    fi
done

[[ -z $SYSTEM ]] && red "不支持当前VPS系统, 请使用主流的操作系统" && exit 1

#安装/更行sing-box
select_sing_box_install_option() {
    local install_option

    echo "请选择 sing-box 的安装版本(默认1)： "
    echo -e "${GREEN}1 ${NC} 下载安装 sing-box(Latest 版本)"
    echo -e "${GREEN}2 ${NC} 下载安装 sing-box(Beta 版本)"
    echo -e "${GREEN}0 ${NC} 退出 "

    while true; do
        read -p "选择执行选项: " install_option
        case $install_option in
            1|"")
                install_latest_sing_box
                break
                ;;
            2)
                install_Pre_release_sing_box
                break
                ;;
            0)
                break
                ;;            
            *)
                red "无效的选择,请重新输入！${NC}"
                ;;
        esac
    done
}

install_latest_sing_box() {
    local arch=$(uname -m)
    echo "arc $arch"
    local url="https://api.github.com/repos/SagerNet/sing-box/releases/latest"
    local download_url

    case $arch in
        x86_64|amd64)
            download_url=$(curl -s $url | grep -o "https://github.com[^\"']*linux-amd64.tar.gz")
            ;;
        armv7l)
            download_url=$(curl -s $url | grep -o "https://github.com[^\"']*linux-armv7.tar.gz")
            ;;
        aarch64|arm64)
            download_url=$(curl -s $url | grep -o "https://github.com[^\"']*linux-arm64.tar.gz")
            ;;
        amd64v3)
            download_url=$(curl -s $url | grep -o "https://github.com[^\"']*linux-amd64v3.tar.gz")
            ;;
        s390x)
            download_url=$(curl -s $url | grep -o "https://github.com[^\"']*linux-s390x.tar.gz")
            ;;            
        *)
            red "不支持的架构：$arch "
            return 1
            ;;
    esac

    if [[ -n $download_url ]]; then
        echo "Downloading Sing-Box..."
        wget -qO sing-box.tar.gz "$download_url" 2>&1 >/dev/null
        tar -xzf sing-box.tar.gz -C /usr/local/bin --strip-components=1
        rm sing-box.tar.gz
        chmod +x /usr/local/bin/sing-box
        green "Sing-Box installed successfully!"
        check_install_type
    else
        red "Unable to retrieve the download URL for Sing-Box"
        return 1
    fi
}

install_Pre_release_sing_box() {
    local arch=$(uname -m)
    local url="https://api.github.com/repos/SagerNet/sing-box/releases"
    local download_url

    case $arch in
        x86_64|amd64)
            download_url=$(curl -s "$url" | jq -r '.[] | select(.prerelease == true) | .assets[] | select(.browser_download_url | contains("linux-amd64.tar.gz")) | .browser_download_url' | head -n 1)
            ;;
        armv7l)
            download_url=$(curl -s "$url" | jq -r '.[] | select(.prerelease == true) | .assets[] | select(.browser_download_url | contains("linux-armv7.tar.gz")) | .browser_download_url' | head -n 1)
            ;;
        aarch64|arm64)
            download_url=$(curl -s "$url" | jq -r '.[] | select(.prerelease == true) | .assets[] | select(.browser_download_url | contains("linux-arm64.tar.gz")) | .browser_download_url' | head -n 1)
            ;;
        amd64v3)
            download_url=$(curl -s "$url" | jq -r '.[] | select(.prerelease == true) | .assets[] | select(.browser_download_url | contains("linux-amd64v3.tar.gz")) | .browser_download_url' | head -n 1)
            ;;
        s390x)
            download_url=$(curl -s "$url" | jq -r '.[] | select(.prerelease == true) | .assets[] | select(.browser_download_url | contains("linux-s390x.tar.gz")) | .browser_download_url' | head -n 1)
            ;;            
        *)
            red "不支持的架构：$arch"
            return 1
            ;;
    esac

    if [[ -n $download_url ]]; then
        echo "Downloading Sing-Box..."
        wget -qO sing-box.tar.gz "$download_url" 2>&1 >/dev/null
        tar -xzf sing-box.tar.gz -C /usr/local/bin --strip-components=1
        rm sing-box.tar.gz
        chmod +x /usr/local/bin/sing-box
        green "Sing-Box installed successfully!"
        check_install_type
    else
        red "Unable to get pre-release download link for Sing-Box"
        return 1
    fi
}

check_install_type() {
    local folder="/usr/local/etc/sing-box"

    if [[ -d $folder ]]; then
        systemctl daemon-reload   
        systemctl enable sing-box
        systemctl start sing-box
        systemctl restart sing-box
    else
        mkdir -p "$folder" && touch "$folder/config.json"
        configure_sing_box_service
        systemctl daemon-reload   
        systemctl enable sing-box
    fi
}

configure_sing_box_service() {
    echo "Configuring sing-box startup service..."
    local service_file="/etc/systemd/system/sing-box.service"

    if [[ -f $service_file ]]; then
        rm "$service_file"
    fi
    
    local service_config='[Unit]
    Description=sing-box service
    Documentation=https://sing-box.sagernet.org
    After=network.target nss-lookup.target

    [Service]
    CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
    AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
    ExecStart=/usr/local/bin/sing-box run -c /usr/local/etc/sing-box/config.json
    ExecReload=/bin/kill -HUP $MAINPID
    Restart=on-failure
    RestartSec=10s
    LimitNOFILE=infinity

    [Install]
    WantedBy=multi-user.target'

    echo "$service_config" >"$service_file"
    green "sing-box startup service has been configured!"
}

#安装/管理warp
install_warp() {
    local config_file="/etc/wireguard/warp.conf"
    local choice
    local choic

    if [[ -e $config_file ]]; then
        read -p "warp 已安装在 $config_file ,进入管理面板？( y/n, 默认为 n ): " choice
        [[ $choice == "y" ]] && warp
    else
        read -p "warp 未安装,现在安装？( y/n, 默认为 n): " choic
        if [[ $choic == "y" ]]; then
            wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh
        fi
    fi

}

#申请/管理证书(acme.sh)
acme_cert_apply() {
    local answer
    local chioce

    if [[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]]; then
        read -p "acme.sh 尚未安装,是否现在安装？( y/n,默认 y ): " answer
        answer="${answer:-y}"
        [[ $answer == "y" ]] && install_acme && acme_cert_apply
    else
        green "acme.sh 已安装!"
        echo -e "${GREEN}1 ${NC} 申请新证书"
        echo -e "${GREEN}2 ${NC} 查看/撤销/删除已申请的证书"
        echo -e "${GREEN}3 ${NC} 手动续期已申请的证书"
        echo -e "${RED}4  卸载acme.sh${NC}"
        echo -e "${GREEN}0 ${NC} 退出"

        while true; do
            read -p "选择执行选项(默认 0 ): " chioce
            case $chioce in
                1)
                    acme_standalone
                    break
                    ;;
                2)
                    revoke_cert
                    break
                    ;;
                3)
                    renew_cert
                    break
                    ;;
                4)
                    uninstall_acme
                    break
                    ;;
                0|"")
                    break
                    ;;
                *)
                    red "无效的选择,请重新输入！${NC}"
                    ;;
            esac
        done
    fi
}

install_acme(){
    local email

    if [[ ! $SYSTEM == "CentOS" ]]; then
        ${PACKAGE_UPDATE[int]}
    fi
    ${PACKAGE_INSTALL[int]} curl wget sudo socat openssl

    if [[ $SYSTEM == "CentOS" ]]; then
        ${PACKAGE_INSTALL[int]} cronie
        systemctl start crond
        systemctl enable crond
    else
        ${PACKAGE_INSTALL[int]} cron
        systemctl start cron
        systemctl enable cron
    fi
    
    read -rp "请输入注册邮箱 (例: admin@gmail.com, 或留空生成随机邮箱): " email
    if [[ -z $email ]]; then
        automail=$(date +%s%N | md5sum | cut -c 1-16)
        email=$automail@gmail.com
        green "已自动生成 gmail 邮箱: $email "
    fi

    curl https://get.acme.sh | sh -s email=$email
    source ~/.bashrc
    bash ~/.acme.sh/acme.sh --upgrade --auto-upgrade

    if [[ -n $(~/.acme.sh/acme.sh -v 2>/dev/null) ]]; then
        #将默认ca切换为letsencrypt
        bash ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

        green "acme.sh 证书一键申请脚本安装成功!"
    else
        red "acme.sh 证书一键申请脚本安装失败!"
    fi
}

acme_standalone(){
    #检查/释放80端口
    check_port

    #检查/关闭warp
    check_warp
    
    #申请证书、安装证书
    apply_cert
}

revoke_cert() {
    local domain

    bash ~/.acme.sh/acme.sh --list
    read -rp "输入要撤销的域名证书(复制 Main_Domain 下显示的域名): " domain
    [[ -z $domain ]] && red "未输入域名,无法执行操作!" && exit 1

    if [[ -n $(bash ~/.acme.sh/acme.sh --list | grep $domain) ]]; then
        bash ~/.acme.sh/acme.sh --revoke -d ${domain} --ecc
        bash ~/.acme.sh/acme.sh --remove -d ${domain} --ecc

        rm -rf ~/.acme.sh/${domain}_ecc
        rm -f /usr/local/etc/acme/$domain.crt /usr/local/etc/acme/$domain.key

        green "撤销 ${domain} 的域名证书成功!"
    else
        red "未找到 ${domain} 的域名证书, 请检查后重新运行!"
    fi
}

renew_cert() {
    bash ~/.acme.sh/acme.sh --cron -f
}

switch_provider() {
    local provider

    echo "设置证书提供商, 默认 Letsencrypt.org "
    echo -e "${GREEN}1 ${NC} Letsencrypt.org "
    echo -e "${GREEN}2 ${NC} BuyPass.com"
    echo -e "${GREEN}3 ${NC} ZeroSSL.com"
    echo -e "${GREEN}0 ${NC} 退出"

    while true; do
        read -p "选择执行选项: " provider
        case $provider in
            1|"")
                bash ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt && green "证书提供商已设置为 Letsencrypt.org ！"
                break
                ;;
            2)
                bash ~/.acme.sh/acme.sh --set-default-ca --server buypass && green "证书提供商已设置为 BuyPass.com ！"
                break
                ;;
            3)
                bash ~/.acme.sh/acme.sh --set-default-ca --server zerossl && green "证书提供商已设置为 ZeroSSL.com ！"
                break
                ;;
            0)
                break
                ;;
            *)
                red "无效的选择,请重新输入!"
                ;;
        esac
    done
}

uninstall_acme() {
    local answer
    local cert_path="/usr/local/etc/acme"
    
    read -p "确定要删除 acme.sh 吗？( y/n,默认 n )： " answer
    answer="${answer:-n}"
    if [[ $answer == "y" ]]; then
        ~/.acme.sh/acme.sh --uninstall
        rm -rf ~/.acme.sh
        [[ -d $cert_path ]] && rm -rf "$cert_path"
        green "acme.sh 证书一键申请脚本已彻底卸载!"
    fi
}

check_port(){
    local choice

    if [[ -z $(type -P lsof) ]]; then
        if [[ ! $SYSTEM == "CentOS" ]]; then
            ${PACKAGE_UPDATE[int]}
        fi
        ${PACKAGE_INSTALL[int]} lsof
    fi

    while true; do
        read -rp "请输入证书申请端口,默认 80 端口: " port
        port="${port:-80}"
        if((port >= 1 && port <= 65535)); then
            echo "正在检测 $port 端口是否占用..."
            if [[ $(lsof -i:$port | grep -i -c "listen") -eq 0 ]]; then
                green "检测到 $port 端口未被占用."
            else
                yellow "检测到目前 $port 端口被其他程序被占用,以下为占用程序信息:"
                lsof -i:"$port"
                read -rp "是否结束进程,释放端口?( y/n,默认 n ): " choice
                choice="${choice:-n}"
                if [[ $choice =~ "y" ]]; then
                    lsof -i:"$port" | awk '{print $2}' | grep -v "PID" | xargs kill -9
                    green "$port 端口已释放!"
                fi
            fi
            break
        else
            red "输入内容错误,请重新输入!"
        fi
    done
}

check_warp() {
    local chioce
    local WARPv4Status=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    local WARPv6Status=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)

    if [[ $WARPv4Status =~ on|plus ]] || [[ $WARPv6Status =~ on|plus ]]; then
        read -p "检测到 warp 已开启,将影响 acme.sh 成功申请证书,是否关闭 warp ?( y/n,默认 y )： " chioce
        chioce="${chioce:-y}"
        if [[ $chioce == "y" ]]; then
            warp o
        fi
    else
        green "检测到 warp 未开启."
    fi
}

apply_cert() {
    local choice
    local domain
    local domainIP
    local cert_path="/usr/local/etc/acme"
    local ipv4=$(curl -s4m8 ip.sb -k | sed -n 1p)
    local ipv6=$(curl -s6m8 ip.sb -k | sed -n 1p)
    local current_ca=$(grep DEFAULT_ACME_SERVER /root/.acme.sh/account.conf | awk -F'=' '{print $2}')

    [[ "$ipv4" ]] && yellow "服务器 ipv4 为: ${ipv4}"
    [[ "$ipv6" ]] && yellow "服务器 ipv6 为: ${ipv6}"

    read -rp "当前证书提供商: $current_ca ,是否切换?( y/n ,默认 n ): " choice
    chioce="${chioce:-n}"
    [[ $chioce == "y" ]] && switch_provider

    while true; do
        read -rp "请输入解析完成的域名: " domain
        if [[ -z $domain ]];then
            red "未输入域名,无法执行操作！"
        else
            green "已输入的域名: $domain"
            break
        fi
    done

    domainIP=$(curl -sm8 ipget.net/?ip="${domain}")

    if [[ $domainIP == $ipv6 ]]; then
        bash ~/.acme.sh/acme.sh --issue -d ${domain} --standalone -k ec-256 --listen-v6 --insecure --httpport ${port}
    elif [[ $domainIP == $ipv4 ]]; then
        bash ~/.acme.sh/acme.sh --issue -d ${domain} --standalone -k ec-256 --insecure --httpport ${port}
    else
        red "域名未完成解析或域名解析的IP与服务器当前IP不匹配."
        exit 1
    fi
    if [[ $? -eq 0 ]]; then
        #安装 $domain 的证书并保存到 $cert_path
        [[ ! -d $cert_path ]] && mkdir -p "$cert_path"
        bash ~/.acme.sh/acme.sh --install-cert -d $domain --key-file $cert_path/$domain.key --fullchain-file $cert_path/$domain.crt --ecc
        echo "$domain" > "$cert_path"/ca.log
        green "证书申请成功!"
        yellow "crt 文件路径: "$cert_path"/"$domain".crt"
        yellow "key 文件路径: "$cert_path"/"$domain".key"
        exit 0
    else
        red "证书申请失败!"
        exit 1
    fi
}

#自签证书
self_sign_cert() {
    local domain
    local cert_path

    while [[ -z $domain ]]; do
        read -p "请输入要签证的域名(例如: example.com): " domain
    done

    while [[ -z $cert_path ]] || [[ ! -d $cert_path ]]; do
        read -rp "请输入证书保存路径(必须为已存在的目录,按回车键确认,默认路径为 /usr/local/etc/cert ): " cert_path
        if [[ -z $cert_path ]]; then
            mkdir -p /usr/local/etc/cert
            cert_path="/usr/local/etc/cert"
        fi
        if [[ ! -d $cert_path ]]; then
            red "错误：指定的路径 '$cert_path' 不存在,请重新输入!"
        fi
    done
    openssl ecparam -genkey -name prime256v1 -out "$cert_path/$domain.key"
    openssl req -new -x509 -days 3650 -key "$cert_path/$domain.key" -out "$cert_path/$domain.crt" -subj "/CN=$domain"

    green "SSL证书和私钥已生成!"
    yellow "crt 文件路径: $cert_path/$domain.crt"
    yellow "key 文件路径: $cert_path/$domain.key"
}

#更新脚本
update_script() {
    wget -O /root/sb.sh https://raw.githubusercontent.com/sleeple2s/sing_box/main/sing_box.sh
    chmod +x /root/sb.sh 
}

open_bbr() {
    local bbr_status=$(sysctl -n net.ipv4.tcp_congestion_control)
    if [ "$bbr_status" != "bbr" ]; then
        echo "net.core.default_qdisc=fq" > /etc/sysctl.conf  
        echo "net.ipv4.tcp_congestion_control=bbr" > /etc/sysctl.conf  
        sysctl -p
    else
        green "已开启bbr"
    fi
}

open_fast_open() {
    local fastopen_status=$(sysctl -n net.ipv4.tcp_fastopen)
    if [ "$bbr_status" != "3" ]; then
        echo "net.ipv4.tcp_fastopen = 3" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
    else
        green "tcp_fast_open已开启"
    fi
}

#卸载sing-box
uninstall_sing_box() {
    local answer

    read -p "确定要删除 sing-box 吗？( y/n,默认 n ) " answer
    answer="${answer:-n}"
    if [[ $answer == "y" ]]; then
        echo "开始卸载 sing-box..."
        systemctl disable sing-box
        rm -rf /usr/local/bin/sing-box
        rm -rf /usr/local/etc/sing-box
        rm -rf /etc/systemd/system/sing-box.service
        systemctl daemon-reload
        green "sing-box 卸载完成!"
    else
        echo "取消卸载操作"
    fi
}

show_sing_box_info() {
    local status_output=$(systemctl status sing-box)
    local version_output=$(sing-box version)

    if [[ $status_output == *Active:\ active* ]]; then
        green "sing-box status  active"
    else
        yellow "sing-box status  not active"
    fi

    if [ $? -eq 0 ]; then
        green "$(echo "$version_output" | head -n 1)"
    else
        yellow "sing-box version 获取失败,跳过处理."
    fi
}

menu() {
    show_sing_box_info
    echo "------------------------------------"
    echo -e "${GREEN}1 ${NC} 安装/更新sing-box"
    echo -e "${GREEN}2 ${NC} 安装/管理warp"
    echo -e "${GREEN}3 ${NC} 申请/管理证书(acme.sh)"
    echo -e "${GREEN}4 ${NC} 自签证书"
    echo -e "${GREEN}5 ${NC} 更新脚本"
    echo -e "${GREEN}6 ${NC} 开启bbr"
    echo -e "${GREEN}7 ${NC} 开启fast-open"
    echo -e "${RED}10 卸载sing-box${NC}"
    echo -e "${GREEN}0 ${NC} 退出脚本"
    echo "------------------------------------"
    read -rp "选择执行选项: " menuInput
    case "$menuInput" in
        1)
            select_sing_box_install_option
            exit 0
            ;;
        2)
            install_warp
            exit 0
            ;;
        3)
            acme_cert_apply
            exit 0
            ;;
        4)
            self_sign_cert
            exit 0
            ;;

        5)
            update_script
            exit 0
            ;;
        6)
            open_bbr
            exit 0
            ;;
        7)
            open_fast_open
            exit 0
            ;;
        10)
            uninstall_sing_box
            exit 0
            ;;
        0)
            exit 0
            ;;
        *) 
            red "无效的选择,请重新输入!"
            menu
            ;;
    esac
}

menu


