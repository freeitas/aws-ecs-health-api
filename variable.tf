variable "cluster_name" {
  default = "aws-ecs-cluster"
}

variable "region" {
  default = "us-east-1"
}

variable "ssm_alb" {
  default = "/aws/ecs/lb/id"
}

variable "ssm_listener" {
  default = "/aws/ecs/lb/listerner"
}

variable "ssm_alb_internal" {
  default = "/aws/ecs/lb/internal/id"
}

variable "ssm_listener_internal" {
  default = "/aws/ecs/lb/internal/listerner"
}

variable "ssm_vpc_id" {
  default = "/aws-vpc/vpc/vpc_id"
}

variable "ssm_private_subnet_1" {
  default = "/aws-vpc/vpc/subnet_private_1a"
}

variable "ssm_private_subnet_2" {
  default = "/aws-vpc/vpc/subnet_private_1b"
}

variable "ssm_private_subnet_3" {
  default = "/aws-vpc/vpc/subnet_private_1c"
}

variable "ssm_service_discovery_namespace" {
  default = "/aws/ecs/cloudmap/namespace"
}