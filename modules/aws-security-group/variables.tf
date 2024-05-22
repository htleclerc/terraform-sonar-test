# Input variable definitions

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "tags" {
  description = "Tags to set on the ressource."
  type        = map(string)
  default     = {}
}
