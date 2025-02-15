#!/bin/bash

# script.sh 실행 로그 기록
exec > /var/log/script.log 2>&1

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
  app-admin:
    container_name: app-admin
    image: yong7317/application-admin:latest
    ports:
      - '8084:8082'
    command: ["java", "-jar", "-Duser.timezone=Asia/Seoul", "/admin-app.jar", "--spring.profiles.active=prod"]
    volumes:
      - /home/ec2-user/backend/log:/var/log
    networks:
      - o2o-network

networks:
  o2o-network:
    external: true
EOT

sudo chown -R ec2-user:ec2-user /home/ec2-user/backend/docker-compose.yml

# Backend Docker Compose 실행
cd /home/ec2-user/backend
docker-compose up -d

# frontend 폴더 생성
sudo -u ec2-user mkdir -p /home/ec2-user/frontend/shop

echo "=== Frontend Shop File Download start to S3 ==="

# AWS CLI를 사용하여 파일 다운로드
sudo -u ec2-user aws s3 cp "s3://${s3_frontend_bucket}/shop" "/home/ec2-user/frontend/shop" --recursive

# 다운로드 성공 여부 확인
if [ $? -eq 0 ]; then
  echo "Frontend Shop File Download success : /home/ec2-user/frontend"
else
  echo "Frontend Shop File Download Fali!"
fi

echo "=== Frontend Shop File Download Completed ==="

# Nginx 설치
sudo dnf install nginx -y

# Nginx 자동 부팅 활성화
sudo systemctl enable nginx

# Nginx 버전 확인
nginx -v

# nginx.conf 파일 생성
cat <<EOT > /etc/nginx/nginx.conf
user root;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
  worker_connections 1024;
}

http {
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
      root  /home/ec2-user/frontend/shop/dist;
      index index.html;
      try_files \$uri /index.html;
    }

    location ~ ^/(api|swagger-ui|v3/api-docs) {
      proxy_pass http://127.0.0.1:8084;
      proxy_set_header Host              \$host;
      proxy_set_header X-Real-IP         \$remote_addr;
      proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;

      proxy_http_version 1.1;
      proxy_set_header   Connection keep-alive;
      proxy_buffering    off;

      add_header Cache-Control no-cache;
      add_header X-Accel-Buffering no;
    }

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

echo "Setup completed successfully!"