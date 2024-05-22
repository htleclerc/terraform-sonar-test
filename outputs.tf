# outputs.tf

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ec2_instance_ids" {
  description = "IDs of EC2 instances"
  value       = module.ec2_instances.instance_ids
}

output "website_bucket_arn" {
  description = "ARN of the bucket"
  value       = module.website_s3_bucket.arn
}

output "website_bucket_name" {
  description = "Name (id) of the bucket"
  value       = module.website_s3_bucket.name
}

output "website_bucket_domain" {
  description = "Domain name of the bucket"
  value       = module.website_s3_bucket.domain
}
