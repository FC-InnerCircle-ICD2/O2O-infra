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

# =================================== Nginx 파일 생성 ============================================================
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
    server_name  _;

    location / {
      rewrite ^/grafana$ /grafana permanent;
      proxy_pass http://127.0.0.1:3001;   # 끝에 슬래시(/) 필수
      proxy_set_header Host               \$host;
      proxy_set_header X-Real-IP          \$remote_addr;
      proxy_set_header X-Forwarded-For    \$proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto  \$scheme;
    }

    # Load configuration files for the default server block.
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

sudo -u ec2-user mkdir -p /home/ec2-user/backend

# Docker Network 생성
docker network create o2o-network

echo "Setup Docker Network!"

# =================================== Docker Compose 파일 생성 ============================================================
cat <<EOT > /home/ec2-user/backend/docker-compose.yml
version: "3.8"

services:
  prometheus:
    image: prom/prometheus:v2.53.3
    container_name: prometheus
    volumes:
      - /home/ec2-user/backend/prometheus/prometheus-prod.yml:/etc/prometheus/prometheus.yml
      - /home/ec2-user/instance_ip.json:/etc/prometheus/targets/instance_ip.json
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-lifecycle'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
      - '--web.listen-address=:9090'
    restart: unless-stopped
    networks:
      - o2o-network

  grafana:
    image: grafana/grafana-oss:11.5.1
    container_name: grafana
    volumes:
      - /home/ec2-user/backend/grafana/config:/etc/grafana
      - grafana_data:/var/lib/grafana
      - /home/ec2-user/backend/grafana/provisioning:/etc/grafana/provisioning
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=${gf_security_admin_user}
      - GF_SECURITY_ADMIN_PASSWORD=${gf_security_admin_password}
    depends_on:
      - prometheus
      - loki
    restart: unless-stopped
    networks:
      - o2o-network

  loki:
    image: grafana/loki:3.3.2
    container_name: loki
    ports:
      - "3100:3100"
    volumes:
      - loki_data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    restart: unless-stopped
    networks:
      - o2o-network

  promtail:
    image: grafana/promtail:2.8.0
    container_name: promtail
    volumes:
      - /home/ec2-user/backend/promtail/config.yml:/etc/promtail/config.yml
      - /var/log:/var/log
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    command: -config.file=/etc/promtail/config.yml
    depends_on:
      - loki
    restart: unless-stopped
    networks:
      - o2o-network

volumes:
  prometheus_data:
  grafana_data:
  loki_data:

networks:
  o2o-network:
    external: true
EOT

sudo chown -R ec2-user:ec2-user /home/ec2-user/backend/docker-compose.yml

# =================================== prometheus 스크립트 파일 생성 ============================================================
cat > /home/ec2-user/prometheus_files.sh <<EOL
#!/bin/bash

ASG_NAME="ProdClientAutoScalingGroup"
TARGET_FILE="/home/ec2-user/instance_ip.json"

# Get instance IPs from ASG
INSTANCE_IPS=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names \$ASG_NAME --query "AutoScalingGroups[].Instances[].InstanceId" --output text | xargs -n1 aws ec2 describe-instances --instance-ids | jq -r '.Reservations[].Instances[].PrivateIpAddress')

LENGTH=${#\INSTANCE_IPS[@]}

INDEX=0

# Generate JSON for Prometheus
echo '[' > \$TARGET_FILE
for IP in "${\INSTANCE_IPS[@]}"; do
  # Check if it is the last element
  if [ \$INDEX -eq $((LENGTH - 1)) ]; then
    echo "  { \"targets\": [\"\$IP:8089\"] }" >> \$TARGET_FILE
  else
    echo "  { \"targets\": [\"\$IP:8089\"] }," >> \$TARGET_FILE
  fi
  # Increment the index
  INDEX=$((INDEX + 1))
done
echo ']' >> \$TARGET_FILE
EOL

sudo chown ec2-user:ec2-user /home/ec2-user/prometheus_files.sh
sudo chmod +x prometheus_files.sh

# =================================== prometheus 설정 파일 생성 ============================================================
sudo -u ec2-user mkdir -p /home/ec2-user/backend/prometheus

cat > /home/ec2-user/backend/prometheus/prometheus-prod.yml <<EOL
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'application-client'
    metrics_path: '/actuator/prometheus'
    file_sd_configs:
      - files:
          - '/etc/prometheus/targets/instance_ip.json'

EOL

sudo chown ec2-user:ec2-user /home/ec2-user/backend/prometheus/prometheus-prod.yml

# =================================== grafana 설정 파일 생성 ============================================================
sudo -u ec2-user mkdir -p /home/ec2-user/backend/grafana/config

cat > /home/ec2-user/backend/grafana/config/grafana.ini <<EOL
[server]
root_url = ${grafana_root_url}
serve_from_sub_path = true
EOL
