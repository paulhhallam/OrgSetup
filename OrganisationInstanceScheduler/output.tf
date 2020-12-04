output "OrgSchedule" {
  value = module.instanceschedulerOrg.OrgSchedule
}
output "ConfigTableName" {
  value = module.instanceschedulerOrg.OrgSchedule["ConfigurationTable"]
}
