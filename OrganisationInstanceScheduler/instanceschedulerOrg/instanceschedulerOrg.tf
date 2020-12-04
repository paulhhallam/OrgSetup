resource "aws_cloudformation_stack" "InstanceSchedulerOrg" {
  name = "InstanceSchedulerOrg"
  template_body = file("${path.module}//instanceschedulerOrg.template")
  capabilities = ["CAPABILITY_IAM"]
  parameters = {
#    InstanceSchedulerAccount = var.OrgAccountId,
    Regions                  = "eu-west-2",
    StartedTags              = "OrgStarted",
    CrossAccountRoles        = "",
    StoppedTags              = "OrgStoped",
    TagName                  = "OrgSchedule"
  }
}

