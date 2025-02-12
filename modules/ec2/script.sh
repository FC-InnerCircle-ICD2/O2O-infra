#!/bin/bash
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

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

# Docker Compose 설치
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "Setup completed Docker Compose!"

# Docker Compose 파일 생성
cat <<EOT > /home/ec2-user/docker-compose.yml
version: '3'
services:
  my-app:
    image: ${ECR_URL}/${IMAGE_NAME}
    restart: always
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
EOT

# Docker Compose 실행
cd /home/ec2-user
docker-compose up -d

echo "Setup completed successfully!"