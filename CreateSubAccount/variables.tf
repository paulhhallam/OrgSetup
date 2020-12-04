# AWS account region for user accounts
variable "region_testing" {
  type    = string
  default = "eu-west-2"
}

### Account variables
variable "bdname" {
  type = string
  description = "The sub account name"
}

variable "bdemail" {
  type = string
  description = "The sub account root email address"
}
