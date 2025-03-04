#!/bin/bash

# script.sh 실행 로그 기록
exec > /var/log/script.log 2>&1

sudo timedatectl set-timezone Asia/Seoul

timedatectl

# Docker 설치
sudo yum update -y
sudo yum install -y docker

# Docker 서비스 시작 및 부팅 시 자동 시작 설정
sudo service docker start
sudo systemctl enable docker

# 현재 사용자에게 Docker 권한 부여
sudo usermod -a -G docker ec2-user

# docker 명령어가 바로 적용이 안될 때
newgrp docker

echo "Setup completed Docker!"

# Docker Compose 설치
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "Setup completed Docker Compose!"

# .aws 디렉토리가 없으면 생성
sudo -u ec2-user mkdir -p /home/ec2-user/.aws

# credentials 파일에 AWS 액세스 키와 비밀 키 설정
cat > /home/ec2-user/.aws/credentials <<EOL
[default]
aws_access_key_id=${aws_access_key_id}
aws_secret_access_key=${aws_secret_access_key}
EOL

# config 파일에 리전 설정
cat > /home/ec2-user/.aws/config <<EOL
[default]
region=${aws_default_region}
output=json
EOL

sudo chown -R ec2-user:ec2-user /home/ec2-user/.aws

aws configure list

# backend 폴더 생성
sudo -u ec2-user mkdir -p /home/ec2-user/backend

echo "=== Backend .env File Download start to S3 ==="

# AWS CLI를 사용하여 파일 다운로드
sudo -u ec2-user aws s3 cp "s3://${s3_backend_bucket}/.env" "/home/ec2-user/backend"

# 다운로드 성공 여부 확인
if [ $? -eq 0 ]; then
  echo "Backend .env File Download success : /home/ec2-user/backend"
else
  echo "Backend .env File Download Fali!"
fi

echo "=== Backend .env File Download Completed ==="

# Docker Network 생성
docker network create o2o-network

echo "Setup Docker Network!"

# Docker Compose 파일 생성
cat <<EOT > /home/ec2-user/backend/docker-compose.yml
version: "3.8"

services:
  app-client:
    container_name: app-client
    image: yong7317/application-client:latest
    env_file:
      - .env
    ports:
      - '8083:8081'
    command: ["java", "-jar", "-Duser.timezone=Asia/Seoul", "/client-app.jar", "--spring.profiles.active=prod"]
    volumes:
      - /home/ec2-user/backend/log:/var/log
    networks:
      - o2o-network

  promtail:
    image: grafana/promtail:2.8.0
    container_name: promtail
    environment:
      - HOSTNAME=$${HOSTNAME}
    volumes:
      - /home/ec2-user/backend/promtail/config.yml:/etc/promtail/config.yml
      - /home/ec2-user/backend/log/application-client.log:/var/log/application-client.log
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    command:
      - "-config.file=/etc/promtail/config.yml"
      - "-config.expand-env=true"
    restart: unless-stopped
    networks:
      - o2o-network

networks:
  o2o-network:
    external: true
EOT

sudo chown -R ec2-user:ec2-user /home/ec2-user/backend/docker-compose.yml

# promtail 폴더 생성
sudo -u ec2-user mkdir -p /home/ec2-user/backend/promtail

# promtail config 파일 생성
cat <<EOT > /home/ec2-user/backend/promtail/config.yml
server:
  http_listen_port: 9080

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://${grafana_root_url}/loki/api/v1/push

scrape_configs:
  - job_name: docker
    static_configs:
      - targets:
          - localhost
        labels:
          job: app-client
          host: $${HOSTNAME}
          __path__: /var/log/*.log
EOT

sudo chown -R ec2-user:ec2-user /home/ec2-user/backend/promtail/config.yml

# Backend Docker Compose 실행
cd /home/ec2-user/backend
docker-compose up -d

# frontend 폴더 생성
sudo -u ec2-user mkdir -p /home/ec2-user/frontend

# Frontend Docker Compose 파일 생성
cat <<EOT > /home/ec2-user/frontend/docker-compose.yml
version: "3.8"

services:
  o2o-fe:
    container_name: o2o-fe
    image: yong7317/o2o-fe:latest
    ports:
      - '3000:3000'
    networks:
      - o2o-network

networks:
  o2o-network:
    external: true
EOT

sudo chown -R ec2-user:ec2-user /home/ec2-user/frontend/docker-compose.yml

# Frontend Docker Compose 실행
cd /home/ec2-user/frontend
docker-compose up -d

# Nginx 설치
sudo dnf install nginx -y

# Nginx 자동 부팅 활성화
sudo systemctl enable nginx

# Nginx 버전 확인
nginx -v

# MaxMind GeoIP 설치
sudo dnf install -y gcc
sudo dnf install -y libmaxminddb libmaxminddb-devel
sudo dnf install -y pcre pcre-devel
sudo dnf install -y zlib zlib-devel

sudo mkdir -p /usr/share/GeoIP/
sudo curl -o /usr/share/GeoIP/GeoLite2-City.mmdb \
    "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=${maxmind_license_key}&suffix=tar.gz"

nginx_version=\$(nginx -v 2>&1 | grep -o '[0-9.]*' | head -1)
cd /usr/local/src
sudo curl -LO http://nginx.org/download/nginx-\$nginx_version.tar.gz
sudo tar zxvf nginx-\$nginx_version.tar.gz

sudo curl -LO https://github.com/leev/ngx_http_geoip2_module/archive/refs/heads/master.zip
sudo unzip master.zip

nginx_version=\$(nginx -v 2>&1 | grep -o '[0-9.]*' | head -1)
cd /usr/local/src/nginx-\$nginx_version
sudo ./configure --with-compat --add-dynamic-module=../ngx_http_geoip2_module-master
sudo make modules

sudo cp objs/ngx_http_geoip2_module.so /usr/lib64/nginx/modules/

ls /usr/lib64/nginx/modules/ | grep geoip2

# nginx.conf 파일 생성
cat <<EOT > /etc/nginx/nginx.conf
user root;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

load_module /usr/lib64/nginx/modules/ngx_http_geoip2_module.so;

events {
  worker_connections 1024;
}

http {
  geoip2 /usr/share/GeoIP/GeoLite2-Country.mmdb {
    auto_reload 60m;
    \$geoip2_metadata_country_build metadata build_epoch;
    \$geoip2_data_country_code country iso_code;
    \$geoip2_data_country_name country names en;
  }

  log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

  access_log  /var/log/nginx/access.log  main;

  sendfile            on;
  tcp_nopush          on;
  keepalive_timeout   65;
  types_hash_max_size 4096;

  include             /etc/nginx/mime.types;
  default_type        application/octet-stream;

  include /etc/nginx/conf.d/*.conf;

  server {
    listen       80;
    listen       [::]:80;
    server_name  clientApplication;

    location / {
      proxy_pass http://127.0.0.1:3000;
      proxy_set_header Host              \$host;
      proxy_set_header X-Real-IP         \$remote_addr;
      proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
    }

    location ~ ^/(api|swagger-ui|v3/api-docs) {
      proxy_pass http://127.0.0.1:8083;
      proxy_set_header Host              \$host;
      proxy_set_header X-Real-IP         \$remote_addr;
      proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
    }

    include /etc/nginx/default.d/*.conf;

    error_page 404 /404.html;
    location = /404.html {
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
    }
  }

  # grafana monitoring port
  server {
    listen       8089;
    server_name  clientApplication;

    location / {
      proxy_pass http://127.0.0.1:8083;
      proxy_set_header Host              \$host;
      proxy_set_header X-Real-IP         \$remote_addr;
      proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
    }

    include /etc/nginx/default.d/*.conf;

    error_page 404 /404.html;
    location = /404.html {
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
    }
  }
}
EOT

# Nginx 상태 확인
sudo systemctl status nginx

# Nginx 실행하기
sudo service nginx start

# backend deploy 파일 생성
cat > /home/ec2-user/backend_deploy.sh <<EOL
#!/bin/bash

docker stop app-client || true
docker rm app-client || true
docker rmi yong7317/application-client:latest || true
docker pull yong7317/application-client:latest
docker-compose -f /home/ec2-user/backend/docker-compose.yml up -d
EOL

sudo chown ec2-user:ec2-user /home/ec2-user/backend_deploy.sh
sudo chmod +x backend_deploy.sh

# frontend deploy 파일 생성
cat > /home/ec2-user/frontend_deploy.sh <<EOL
#!/bin/bash

docker stop o2o-fe || true
docker rm o2o-fe || true
docker rmi yong7317/o2o-fe:latest || true
docker pull yong7317/o2o-fe:latest
docker-compose -f /home/ec2-user/frontend/docker-compose.yml up -d
EOL

sudo chown ec2-user:ec2-user /home/ec2-user/frontend_deploy.sh
sudo chmod +x frontend_deploy.sh

echo "Setup completed successfully!"