#!/bin/bash

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

# Docker Network 생성
docker network create o2o-network

echo "Setup Docker Network!"

# backend 폴더 생성
mkdir -p /home/ec2-user/backend

# Docker Compose 파일 생성
cat <<EOT > /home/ec2-user/backend/docker-compose.yml
version: "3.8"

services:
  store-mongo:
    container_name: store-mongo
    image: yong7317/mongo-o2o:latest
    ports:
      - '27017:27017'
    volumes:
      - /home/ec2-user/data/mongo-data:/data/db
    networks:
      - o2o-network

  store-redis:
    container_name: store-redis
    image: redis:7.0.15
    ports:
      - '6379:6379'
    networks:
      - o2o-network

  order-postgres:
    container_name: order-postgres
    image: postgres:17.2
    ports:
      - '5432:5432'
    environment:
      POSTGRES_USER: "${postgres_user}"
      POSTGRES_PASSWORD: "${postgres_password}"
    volumes:
      - /home/ec2-user/data/postgres-data:/var/lib/postgresql/data
    networks:
      - o2o-network

networks:
  o2o-network:
    external: true
EOT

# Docker Compose 실행
cd /home/ec2-user/backend
docker-compose up -d

echo "Setup completed successfully!"