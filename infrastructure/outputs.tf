# Outputs principaux

output "aws_region" {
  value       = var.aws_region
  description = "Région AWS utilisée"
}

output "project_name" {
  value       = var.project_name
  description = "Nom du projet"
}

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID du VPC"
}

output "public_subnets" {
  value       = aws_subnet.public[*].id
  description = "IDs des subnets publics"
}

output "private_subnets" {
  value       = aws_subnet.private[*].id
  description = "IDs des subnets privés"
}

output "ec2_security_group_id" {
  value       = aws_security_group.ec2.id
  description = "ID du security group EC2"
}

output "glue_security_group_id" {
  value       = aws_security_group.glue.id
  description = "ID du security group Glue"
}

output "glue_job_role_arn" {
  value       = aws_iam_role.glue_job_role.arn
  description = "ARN du rôle IAM pour le job Glue"
}

output "ec2_instance_profile_name" {
  value       = aws_iam_instance_profile.ec2_profile.name
  description = "Nom du profil instance EC2"
}
