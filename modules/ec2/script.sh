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

# backend 폴더 및 flyway 폴더 생성
sudo -u ec2-user mkdir -p /home/ec2-user/backend/flyway/migration

echo "=== Config File Download start to S3 ==="

# AWS CLI를 사용하여 파일 다운로드
sudo -u ec2-user aws s3 cp "s3://${s3_backend_bucket}/flyway" "/home/ec2-user/backend/flyway" --recursive

# 다운로드 성공 여부 확인
if [ $? -eq 0 ]; then
  echo "Flyway Config File Download success : /home/ec2-user/backend"
else
  echo "Flyway Config File Download Fali!"
fi

echo "=== Config File Download Completed ==="

# Docker Network 생성
docker network create o2o-network

echo "Setup Docker Network!"

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
      POSTGRES_USER: ${postgres_user}
      POSTGRES_PASSWORD: ${postgres_password}
      POSTGRES_DB: o2o
    volumes:
      - /home/ec2-user/data/postgres-data:/var/lib/postgresql/data
    networks:
      - o2o-network

  app-oss:
    container_name: app-oss
    image: yong7317/application-oss:latest
    ports:
      - '8085:8085'
    command: ["java", "-jar", "-Duser.timezone=Asia/Seoul", "/oss-app.jar", "--spring.profiles.active=prod"]
    volumes:
      - /home/ec2-user/backend/log:/var/log
    networks:
      - o2o-network
    depends_on:
      - order-postgres

  migrate-postgres:
    image: flyway/flyway:7
    container_name: migrate-postgres
    environment:
      - FLYWAY_DB_URL=jdbc:postgresql://order-postgres/o2o
      - FLYWAY_DB_USER=${postgres_user}
      - FLYWAY_DB_PASSWORD=${postgres_user}
    command: migrate
    volumes:
      - /home/ec2-user/backend/flyway/flyway.conf:/flyway/conf/flyway.conf
      - /home/ec2-user/backend/flyway/migration:/flyway/sql
    networks:
      - o2o-network

networks:
  o2o-network:
    external: true
EOT

sudo chown -R ec2-user:ec2-user /home/ec2-user/backend/docker-compose.yml

# 배포 스크립트 파일 생성
cat > /home/ec2-user/deploy.sh <<EOL
#!/bin/bash

docker stop app-oss || true
docker rm app-oss || true
docker rmi yong7317/application-oss:latest || true
docker pull yong7317/application-oss:latest
docker-compose -f /home/ec2-user/backend/docker-compose.yml up -d
EOL

sudo chown ec2-user:ec2-user /home/ec2-user/deploy.sh
sudo chmod +x deploy.sh

# Docker Compose 실행
cd /home/ec2-user/backend
docker-compose up -d

echo "Setup completed successfully!"