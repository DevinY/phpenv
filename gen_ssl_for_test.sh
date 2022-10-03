#!/bin/bash
base_path=$(pwd)
mkdir -p ${base_path}/etc/ssl
cp etc/default-ssl.conf.sample etc/default-ssl.conf
#檢測v3.ext是否存在，沒有就建立
if [ ! -f etc/v3.ext ];then
    cat etc/v3.ext.template > etc/v3.ext
fi

if [ ! $1 ]; then
    echo "*.test is required."
    echo "e.g., $0 [subdomain]"
    exit
fi

#檢測是否為Mac環境
uname -a|grep -q 'Darwin'
if [ $? -eq 0 ]; then
    security find-certificate -c "projsrv.test" -a -Z | \
      sudo awk '/SHA-1/{system("security delete-certificate -Z "$NF)}'
fi

#新增域名到v3_req
DNS_INDEX=$(grep -E "DNS.\d+" etc/v3.ext|wc -l)
NEW_RECORD="DNS.$((DNS_INDEX+1))=$1.test"

grep -q $1.test etc/v3.ext

#不存再再加
if [ $? -gt 0 ]; then
    echo $NEW_RECORD >> etc/v3.ext
fi

#檢測電腦的hosts是否有域名
grep -q "127.0.0.1 $1" /etc/hosts
if [ $? -gt 0 ]; then
    echo "Add $1.test to /etc/hosts"
    echo "127.0.0.1 ${1}.test" |sudo tee -a '/etc/hosts'
fi

cat etc/v3.ext

#產生憑證
openssl req \
-new -newkey rsa:2048 -sha256 \
-days 3650 -nodes -x509 -keyout ${base_path}/etc/ssl/cert.key -out ${base_path}/etc/ssl/cert.crt \
-config ${base_path}/etc/v3.ext -extensions 'v3_req'
#存入鑰匙圈
if [ $? -eq 0 ]; then
    echo "add trusted cert to keyring"
    sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" ${base_path}/etc/ssl/cert.crt
fi

. reload
