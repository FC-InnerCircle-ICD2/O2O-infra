resource "aws_security_group" "MyDBSecurityGroup" {
  name = "MyDBSecurityGroup"
  description = "Permit PostgresSQL(5342)"
  vpc_id = var.vpc_resource.id

  ingress {
    from_port       = 5342
    to_port         = 5342
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"  # -1 인 경우 모든 트래픽
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MyDBSecurityGroup"
  }
}

resource "aws_db_subnet_group" "MyDBSubnetGroup" {
  name       = "mydbsubnetgroup"
  subnet_ids = [var.vpc_private_1_subnet.id, var.vpc_private_2_subnet.id]
  description = "Subnet group for mydb"

  tags = {
    Name = "MyDBSubnetGroup"
  }
}

resource "aws_rds_cluster" "MyDBCluster" {
  depends_on = [aws_security_group.MyDBSecurityGroup, aws_db_subnet_group.MyDBSubnetGroup]
  cluster_identifier      = "mydb"
  engine                  = "postgres"
  engine_version          = "17.2"
  availability_zones      = ["ap-northeast-2a", "ap-northeast-2c"]
  database_name           = "o2o"
  master_username         = "root"
  master_password         = "qwer1234."
  engine_mode             = "provisioned"
  skip_final_snapshot     = true
  vpc_security_group_ids = [aws_security_group.MyDBSecurityGroup.id]
  db_subnet_group_name = aws_db_subnet_group.MyDBSubnetGroup.name
}

resource "aws_rds_cluster_instance" "MyDB1" {
  depends_on = [aws_rds_cluster.MyDBCluster]
  identifier         = "mydb-1"
  cluster_identifier = aws_rds_cluster.MyDBCluster.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.MyDBCluster.engine
  engine_version     = aws_rds_cluster.MyDBCluster.engine_version
  availability_zone  = "ap-northeast-2a"
  db_subnet_group_name = aws_db_subnet_group.MyDBSubnetGroup.name
  auto_minor_version_upgrade = false
}

resource "aws_rds_cluster_instance" "MyDB2" {
  depends_on = [aws_rds_cluster_instance.MyDB1]
  identifier         = "mydb-2"
  cluster_identifier = aws_rds_cluster.MyDBCluster.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.MyDBCluster.engine
  engine_version     = aws_rds_cluster.MyDBCluster.engine_version
  availability_zone  = "ap-northeast-2c"
  db_subnet_group_name = aws_db_subnet_group.MyDBSubnetGroup.name
  auto_minor_version_upgrade = false
}
