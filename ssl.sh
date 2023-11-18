#!/bin/bash
YELLOW="\033[33m"

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

# 提示用户输入要签证的域名
read -p "请输入要签证的域名 (例如: example.com): " DOMAIN_NAME

# 检查输入是否为空
if [ -z "$DOMAIN_NAME" ]; then
    echo "错误：域名不能为空。"
    exit 1
fi

# 提示用户输入证书保存路径
CERT_PATH=""
while [ -z "$CERT_PATH" ] || [ ! -d "$CERT_PATH" ]; do
    read -p "请输入证书保存路径（必须为已存在的目录，按回车键确认，默认路径为 /root/cert）: " CERT_PATH

    # 设置默认证书保存路径
    if [ -z "$CERT_PATH" ]; then
        # 创建目录（如果不存在）
        mkdir -p /root/cert
        CERT_PATH="/root/cert"
    fi

    # 检查用户输入的路径是否存在，如果不存在则提示用户重新输入
    if [ ! -d "$CERT_PATH" ]; then
        echo "错误：指定的路径 '$CERT_PATH' 不存在，请重新输入。"
    fi
done

# 生成私钥
openssl ecparam -genkey -name prime256v1 -out "$CERT_PATH/$DOMAIN_NAME.key"

# 生成自签名证书（.crt 格式）
openssl req -new -x509 -days 3650 -key "$CERT_PATH/$DOMAIN_NAME.key" -out "$CERT_PATH/$DOMAIN_NAME.crt" -subj "/CN=$DOMAIN_NAME"

echo "SSL证书和私钥已生成并保存在 $CERT_PATH 目录下"
yellow "证书 crt 文件路径如下: $CERT_PATH/$DOMAIN_NAME.crt"
yellow "私钥 key 文件路径如下: $CERT_PATH/$DOMAIN_NAME.key"


