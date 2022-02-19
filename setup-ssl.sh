#!/bin/bash

mkdir -p /etc/nginx/ssl/sheepymeh.ml
mkdir -p /var/www/challenges
openssl genrsa 4096 > /etc/nginx/ssl/account.key
openssl ecparam -genkey -name secp384r1 -noout -out /etc/nginx/ssl/sheepymeh.ml/domain.key
openssl req -new -sha256 -key /etc/nginx/ssl/sheepymeh.ml/domain.key -subj '/' -addext 'subjectAltName = DNS:sheepymeh.ml, DNS:www.sheepymeh.ml, DNS:dev.sheepymeh.ml, DNS:vault.sheepymeh.ml, DNS:cloud.sheepymeh.ml' > /etc/nginx/ssl/sheepymeh.ml/domain.csr
wget -qO /usr/local/bin/acme_tiny.py https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py
chmod +x /usr/local/bin/acme_tiny.py
/usr/local/bin/acme_tiny.py --account-key /etc/nginx/ssl/account.key --csr /etc/nginx/ssl/sheepymeh.ml/domain.csr --acme-dir /var/www/challenges/ > /etc/nginx/ssl/sheepymeh.ml/signed_chain.crt
