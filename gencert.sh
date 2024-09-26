#!/bin/bash


password=1234
# read -p "设置 CA 密码：" password
echo ""

# 创建 cert 目录
cert_dir="cert"
mkdir -p $cert_dir

# 证书的基本信息
days=36500
country="CN"
state="Shanghai"
locality="Shanghai"
organization="registry"
organizational_unit="registry"
common_name="registry.com"

# 生成自签名的 CA 私钥和证书
generate_ca() {
    echo "正在生成自签名的 CA 私钥和证书..."
    openssl genrsa -des3 -out $cert_dir/ca.key -passout pass:"$password" 4096
    openssl req -x509 -new -key $cert_dir/ca.key -out $cert_dir/ca.crt -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizational_unit/CN=$common_name" -days $days -passin pass:"$password"
}

# 生成服务器私钥
gen_server_rsa() {
    echo "生成服务器私钥..."
    openssl genrsa -out $cert_dir/server.key 4096
}

# 生成服务器证书签署请求
gen_server_csr() {
    echo "生成服务器证书签名请求..."
    openssl req -new -key $cert_dir/server.key -out $cert_dir/server.csr  -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizational_unit/CN=$common_name"
}


# 使用 CA 对 CSR 进行签名，生成服务器证书
sign_server_certificate() {
    echo "正在使用 CA 对 CSR 进行签名，生成服务器证书..."
    openssl x509 -req -in $cert_dir/server.csr -CA $cert_dir/ca.crt -CAkey $cert_dir/ca.key -CAcreateserial -out $cert_dir/server.crt -days $days -passin pass:"$password" -extfile extfile.txt
}

# 执行证书生成流程
main() {
    # generate_ca
    # gen_server_rsa
    # gen_server_csr
    # sign_server_certificate
    echo "please modify gencert.sh to execute the logic you want\n"
}

main

