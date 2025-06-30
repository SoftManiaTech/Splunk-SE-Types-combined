variable "aws_region" {
  description = "AWS region where resources will be created."
  type        = string
}

variable "instance_name" {
  description = "The name tag for the EC2 instance."
  type        = string
}

variable "usermail" {
  description = "The email address of the instance owner."
  type        = string
}

variable "key_name" {
  description = "Base name for the EC2 Key Pair."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (e.g. t2.micro, t3.medium)."
  type        = string
}

variable "storage_size" {
  description = "Root volume storage size in GB."
  type        = number
  default     = 30
}

variable "quotahours" {
  description = "Total allowed EC2 running hours for the user."
  type        = number

}

variable "hoursperday" {
  description = "Allowed EC2 running hours per day."
  type        = number

}

variable "category" {
  description = "Category for the instance (example: Dev, Prod, Test)."
  type        = string
}

variable "planstartdate" {
  description = "Plan start date in ISO 8601 format (example: 2024-07-01T00:00:00Z)."
  type        = string

}

variable "user_data" {
  description = "User data script to run at instance launch (optional)."
  type        = string
  default     = ""
}