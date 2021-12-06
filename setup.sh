#!/bin/bash

apt update
apt -y upgrade

cat <<EOF >/etc/apt/sources.list.d/nginx.list
deb https://nginx.org/packages/ubuntu/ $(lsb_release -cs) nginx
deb-src https://nginx.org/packages/ubuntu/ $(lsb_release -cs) nginx
EOF
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62

apt install -y software-properties-common dirmngr apt-transport-https
apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
add-apt-repository "deb [arch=amd64,arm64,ppc64el,s390x] https://mirror.djvg.sg/mariadb/repo/10.6/ubuntu $(lsb_release -cs) main"

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" >/etc/apt/sources.list.d/docker.list
apt update
apt install -y nginx mariadb-server docker-ce docker-ce-cli containerd.io
systemctl enable --now nginx

mysql_secure_installation

ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow from 172.17.0.0/16 to any port 3306

nc_db_pass=$(head /dev/urandom | tr -dc _A-Za-z0-9 | head -c48)
vw_db_pass=$(head /dev/urandom | tr -dc _A-Za-z0-9 | head -c48)
vw_admin=$(head /dev/urandom | tr -dc _A-Za-z0-9 | head -c48)

mysql -u root <<EOF
	CREATE USER 'vaultwarden'@'localhost' IDENTIFIED BY '${vw_db_pass}';
	CREATE DATABASE vaultwarden;
	GRANT ALL PRIVILEGES ON vaultwarden.* TO 'vaultwarden'@'172.17.%';

	CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY '${nc_db_pass}';
	CREATE DATABASE nextcloud;
	GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'172.17.%';

	FLUSH PRIVILEGES;
EOF
cat <<EOF >>/etc/mysql/my.cnf
[mysqld]
skip-networking=0
skip-bind-address
EOF

docker pull vaultwarden/server:latest
docker build -t nc nc

docker run -d --add-host=host.docker.internal:host-gateway --name vaultwarden -v /var/vaultwarden/:/data/ -p 127.0.0.1:8001:80 -p 127.0.0.1:8002:3012 --restart=unless-stopped -e "ADMIN_TOKEN=${vw_admin}" -e "DATABASE_URL=mysql://vaultwarden:${vw_db_pass}@host.docker.internal/vaultwarden" vaultwarden/server:latest
docker run -d --add-host=host.docker.internal:host-gateway --name nextcloud -v /var/nextcloud/:/var/www/html -p 127.0.0.1:8003:9000 -e "MYSQL_PASSWORD=${nc_db_pass}" --restart=unless-stopped nc
