Create a 9-5 M-F schedule to be used by a set of hosts.

On the Cohort account:
Add a tag to each node that will use tghe new schedule
e.g. 
  Name=OrgSchedule,Value=OSHours

On the Organisation account:
Amend the DynamoDB table InstanceSchedulerOrg-ConfigTable-..... to have the new schedule
e.g.
Create the schedule "OSHours" by duplicating the CohortHours schedule and changing the "periods" field to "office-hours"
Or use the scheduler cli
$ scheduler-cli create-schedule --stack InstanceScheduler --name OSHours --periods office-hours --timezone UTC


