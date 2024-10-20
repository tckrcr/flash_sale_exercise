resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_rds_cluster" "main" {
  count                  = 4
  cluster_identifier     = "${var.environment}-db-cluster-${count.index + 1}"
  engine                 = "aurora-postgresql"
  engine_version         = "13.7"
  availability_zones     = var.availability_zones
  database_name          = "mydb${count.index + 1}"
  master_username        = "admin"
  master_password        = random_password.db_password[count.index].result
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  skip_final_snapshot = true
}

resource "aws_rds_cluster_instance" "main" {
  count               = 8
  identifier          = "${var.environment}-db-instance-${count.index + 1}"
  cluster_identifier  = aws_rds_cluster.main[floor(count.index / 2)].id
  instance_class      = "db.r5.large"
  engine              = aws_rds_cluster.main[floor(count.index / 2)].engine
  engine_version      = aws_rds_cluster.main[floor(count.index / 2)].engine_version
}

resource "random_password" "db_password" {
  count   = 4
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_credentials" {
  count = 4
  name  = "${var.environment}-db-credentials-${count.index + 1}"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  count         = 4
  secret_id     = aws_secretsmanager_secret.db_credentials[count.index].id
  secret_string = jsonencode({
    username = aws_rds_cluster.main[count.index].master_username
    password = random_password.db_password[count.index].result
    host     = aws_rds_cluster.main[count.index].endpoint
    port     = aws_rds_cluster.main[count.index].port
    dbname   = aws_rds_cluster.main[count.index].database_name
  })
}

output "db_endpoints" {
  value = aws_rds_cluster.main[*].endpoint
}

output "db_secret_arns" {
  value = aws_secretsmanager_secret.db_credentials[*].arn
}