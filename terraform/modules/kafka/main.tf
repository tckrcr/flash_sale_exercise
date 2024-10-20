resource "aws_security_group" "kafka" {
  name        = "${var.environment}-kafka-sg"
  description = "Security group for Kafka"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 9092
    to_port     = 9092
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

resource "aws_msk_cluster" "main" {
  cluster_name           = "${var.environment}-kafka-cluster"
  kafka_version          = "2.8.1"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type   = "kafka.t3.small"
    client_subnets  = var.subnet_ids
    security_groups = [aws_security_group.kafka.id]
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.kafka.arn
  }

  configuration_info {
    arn      = aws_msk_configuration.main.arn
    revision = 1
  }
}

resource "aws_kms_key" "kafka" {
  description = "KMS key for Kafka cluster"
}

resource "aws_msk_configuration" "main" {
  name              = "${var.environment}-kafka-configuration"
  kafka_versions    = ["2.8.1"]
  server_properties = <<PROPERTIES
auto.create.topics.enable=true
delete.topic.enable=true
PROPERTIES
}

resource "aws_instance" "kafka_consumers" {
  count         = 2
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  subnet_id     = var.subnet_ids[0]

  vpc_security_group_ids = [aws_security_group.kafka.id]

  tags = {
    Name = "${var.environment}-kafka-consumer-${count.index + 1}"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y java-1.8.0-openjdk
              wget https://archive.apache.org/dist/kafka/2.8.1/kafka_2.13-2.8.1.tgz
              tar -xzf kafka_2.13-2.8.1.tgz
              mv kafka_2.13-2.8.1 /opt/kafka
              echo "${aws_msk_cluster.main.bootstrap_brokers}" > /opt/kafka/config/bootstrap-servers
              EOF
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

output "kafka_bootstrap_brokers" {
  value = aws_msk_cluster.main.bootstrap_brokers
}

output "kafka_consumer_ips" {
  value = aws_instance.kafka_consumers[*].private_ip
}