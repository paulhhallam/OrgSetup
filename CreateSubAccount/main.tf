resource "aws_organizations_account" "account" {
  name  = var.bdname
  email = var.bdemail
}
