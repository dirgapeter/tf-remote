variable "project" {
  description = "Project of the remote state. Also used as a prefix in names of related resources."
  type        = string
}

variable "environment" {
  description = "Environment of the remote state. Also used as a prefix in names of related resources."
  type        = string
}

variable "path" {
  description = "State file name, i.e. terraform"
  type        = string
  default     = "terraform"
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

variable "suffix" {
  description = "A suffix in names with delimiter '-' included"
  type        = string
  default     = "-tf-remote-state"
}

variable "manage_log_bucket" {
  description = "Defines whether this module should generate and manage its own s3 bucket for logging"
  type        = bool
  default     = true
}

variable "manage_iam_role" {
  description = "Defines whether this module should generate and manage iam role for access"
  type        = bool
  default     = true
}

variable "logging_prefix" {
  description = "A prefix in names for logging bucket"
  type        = string
  default     = "logs/"
}

variable "dynamodb_billing_mode" {
  description = "The DynamoDB billing mode. PAY_PER_REQUEST or PROVISIONED"
  type        = string
  default     = "PAY_PER_REQUEST"
}
