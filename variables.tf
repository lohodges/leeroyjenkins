variable "aws_region" {
  description = "AWS Region for the Echobase fleet to patrol."
  type        = string
  #default     = "us-east-2"
  default = "ap-northeast-1"
}

variable "aws_region_acm" {
  description = "CloudFront certifcate must be in us-east-1"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for naming. Students should change from 'chewbacca' to their own."
  type        = string
  default     = "echobase"
}

variable "vpc_cidr" {
  description = "VPC CIDR (use 10.x.x.x/xx as instructed)."
  type        = string
  default     = "10.124.0.0/16" # TODO: student supplies
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.124.1.0/24", "10.124.2.0/24"] # TODO: student supplies
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.124.101.0/24", "10.124.102.0/24"] # TODO: student supplies
}

variable "azs" {
  description = "Availability Zones list (match count with subnets)."
  type        = list(string)
  #default     = ["us-east-2a", "us-east-2b"] # TODO: student supplies
  default = ["ap-northeast-1a", "ap-northeast-1c"] # TODO: student supplies
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 app host."
  type        = string
  #default     = "ami-06cce67a5893f85f9" # ap-northeast-1
  default = "ami-088b486f20fab3f0e" # ap-northeast-1 for Jenkins
  # default     = "ami-06f1fc9ae5ae7f31e" # us-east-2
}

variable "ec2_instance_type" {
  description = "EC2 instance size for the app."
  type        = string
  #default     = "t2.micro" # free tier eligible (ap-northeast-1)
  default = "t3.xlarge" # free tier eligible (ap-northeast-1) for Jenkins
}

variable "db_engine" {
  description = "RDS engine."
  type        = string
  default     = "mysql"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "notesappdb" # Students can change
  #default     = "labdb" # Students can change
}

variable "db_username" {
  description = "DB master username (students should use Secrets Manager in 1B/1C)."
  type        = string
  default     = "admin" # TODO: student supplies
}

# added by Lonnie Hodges on 2026-01-20
# COMMENTED out to stop using plaintext password that is visibile in Git and Github
# variable "db_password" {
#   description = "DB master password (DO NOT hardcode in real life; for lab only)."
#   type        = string
#   sensitive   = true
#   default     = "" # TODO: student supplies
# }

variable "sns_email_endpoint" {
  description = "Email for SNS subscription (PagerDuty simulation)."
  type        = string
  default     = "lonnie.hodges@robustci.com" # TODO: student supplies
}

# added by Lonnie Hodges 2026-01-17
# copied from 1c_bonus_variables.tf
# variable "domain_name" {
#   description = "aliases for passportog.com"
#   type        = string
#   default     = "passportog.com"
# }

# variable "app_subdomain" {
#   description = "aliases for app.passportog.com"
#   type        = string
#   default     = "app"
# }

variable "domain_name" {
  description = "aliases for echobase.click"
  type        = string
  default     = "echobase.click"
}

variable "app_subdomain" {
  description = "aliases for app.echobase.click"
  type        = string
  default     = "app"
}

variable "certificate_validation_method" {
  description = "ACM validation method. Students can do DNS (Route53) or EMAIL."
  type        = string
  default     = "DNS"
}

variable "enable_waf" {
  description = "Toggle WAF creation."
  type        = bool
  default     = true
}

variable "alb_5xx_threshold" {
  description = "Alarm threshold for ALB 5xx count."
  type        = number
  default     = 10
}

variable "alb_5xx_period_seconds" {
  description = "CloudWatch alarm period."
  type        = number
  default     = 300
}

variable "alb_5xx_evaluation_periods" {
  description = "Evaluation periods for alarm."
  type        = number
  default     = 1
}
# ^^^ added by Lonnie Hodges 2026-01-17

variable "manage_route53_in_terraform" {
  description = "If true, create/manage Route53 hosted zone + records in Terraform."
  type        = bool
  default     = true
}

variable "route53_hosted_zone_id" {
  description = "If manage_route53_in_terraform=false, provide existing Hosted Zone ID for domain."
  type        = string
  # change to your zone ID
  default = "Z0828030PI6PCZKRD9SW"
}

variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3."
  type        = bool
  default     = true
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs."
  type        = string
  default     = "alb-access-logs"
}

# added by Lonnie Hodges on 2026-01-21 (1c_bonus-E.md)
variable "waf_log_destination" {
  description = "Choose ONE destination per WebACL: cloudwatch | s3 | firehose"
  type        = string
  default     = "cloudwatch"
  #default = "s3"
  #default = "firehose"
}

# added by Lonnie Hodges on 2026-02-02
variable "cf_log_destination" {
  description = "Choose ONE destination for CloudFront: s3 | firehose"
  type        = string
  default     = "s3"
  #default = "firehose"
}

variable "waf_log_retention_days" {
  description = "Retention for WAF CloudWatch log group."
  type        = number
  default     = 14
}

variable "enable_waf_sampled_requests_only" {
  description = "If true, students can optionally filter/redact fields later. (Placeholder toggle.)"
  type        = bool
  default     = false
}
# ^^^ added by Lonnie Hodges on 2026-01-21