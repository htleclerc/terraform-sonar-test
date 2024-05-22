# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Output variable definitions

output "alb_sg_ids" {
  description = "Security group of the ELB"
  value       = [aws_security_group.alb.id]
}

output "ecs_sg_ids" {
  description = "Security group of the ECS"
  value       = [aws_security_group.ecs.id]
}

output "ec2_sg_ids" {
  description = "Security group of the EC2"
  value       = [aws_security_group.ec2.id]
}

output "rds_sg_ids" {
  description = "Security group of the RDS"
  value       = [aws_security_group.rds.id]
}
