These instructions will install the AWS instance scheduler as described in the AWS documentation.

The instance scheduler is controlled from the Organisation account; the cohort/sub account setup is completed elsewhere

Download, extract and install the AWS scheduler cli
===================================================
Using the instructions in https://docs.aws.amazon.com/solutions/latest/instance-scheduler/appendix-a.html download 

https://s3.amazonaws.com/solutions-reference/aws-instance-scheduler/latest/scheduler-cli.zip

unzip scheduler-cli.zip

cd .\scheduler-cli\

sudo python3 setup.py install

Instructions For the Organisation account
=========================================

set the AWS profile to your organisation account 

$ aws configure

Changes
=======
To change the tag name used then edit instance-schedulerKey.template.

To change the scheduler tag then edit StackParams.json and change "OrgSchedule" to your choice.

i.e. look for the following section in the file and modify.
        "TagName": {
            "Type": "String",
            "Default": "OrgSchedule",
            "MinLength": 1,
            "MaxLength": 127,
            "Description": "Name of tag to use for associating instance schedule schemas with service instances."
        },

To change the scheduler region then edit StackParams.json and change "eu-west-2" to your choice or just "".

To create the stack
===================
$ aws cloudformation create-stack --stack-name InstanceScheduler --template-body file://instance-schedulerKey.template --parameters file://StackParams.json --capabilities CAPABILITY_NAMED_IAM

  This will almost immediately return information such as:
  {
    "StackId": "arn:aws:cloudformation:eu-west-2:454*********:stack/InstanceScheduler/22ca9e90-dc75-11ea-8ee4-029db6d88004"
  }
  This does not mean the stack has been built but rather that the build is in progress.

n.b. If the stack fails and performs a rollback you must delete the stack 
	$ aws cloudformation delete-stack --stack-name InstanceScheduler
before attempting to rebuild using the create-stack command.

  n.b. Re CAPABILITY_NAMED_IAM
    # In CodePipeline CloudFormation you can add it like this to allow execution of the created change_set in the deploy action:
    Configuration:
        StackName: !Ref GitHubRepository
        ActionMode: CHANGE_SET_REPLACE
        Capabilities: CAPABILITY_NAMED_IAM
        RoleArn: arn:aws:iam::818272543125:role/events-list-codepiplinerole
        ChangeSetName: !Join ["",[!Ref GitHubRepository, "-changeset"]]
        TemplatePath: MyAppBuild::sam_post.yaml

To monitor the build progress we can use:
$ aws cloudformation describe-stack-events  --stack-name InstanceScheduler
$ aws cloudformation list-stacks

  When complete we have:
  3 DynamoDB tables:
     InstanceScheduler-StateTable-nnnnn
     InstanceScheduler-MaintenanceWindowTable-nnnnn
     InstanceScheduler-ConfigTable-nnnnn
     Tags are:
          aws:cloudformation:stack-name : InstanceScheduler
  A Lambda function
     InstanceScheduler-InstanceSchedulerMain (Description=EC2 and RDS instance scheduler, version v1.3.2)
     Tags are:
          aws:cloudformation:stack-name : InstanceScheduler
          aws:cloudformation:stack-id   : arn:aws:cloudformation:eu-west-2:454**********:stack/InstanceScheduler/22ca9e90-dc75-11ea-8ee4-029db6d88004
          aws:cloudformation:logical-id : Main
  A Cloudwatch rule
     InstanceScheduler-SchedulerRule-nnnnn (Description=Instance Scheduler - Rule to trigger instance for scheduler function version v1.3.2)
  An IAM Role
    SchedulerRole
    Tags are:
        cloudformation:stack-name : InstanceScheduler
  An SNS topic
    InstanceScheduler-InstanceSchedulerSnsTopic-nnnnn
    Ttags are:
        cloudformation:stack-name : InstanceScheduler
  A KMS key
    instance-scheduler-encryption-key

To delete the stack:
====================
$ aws cloudformation delete-stack --stack-name InstanceScheduler
  This will return the $ prompt almost immediately

$ aws cloudformation list-stacks
  output will be:
  {
      "StackSummaries": [
        {
            "StackId": "arn:aws:cloudformation:eu-west-2:454*********:stack/InstanceScheduler/22ca9e90-dc75-11ea-8ee4-029db6d88004",
            "StackName": "InstanceScheduler",
            "TemplateDescription": "Instance-scheduler, version v1.3.2",
            "CreationTime": "2020-08-12T08:23:44.303000+00:00",
            "DeletionTime": "2020-08-12T08:54:54.573000+00:00",
            "StackStatus": "DELETE_COMPLETE",
            "DriftInformation": {
                "StackDriftStatus": "NOT_CHECKED"
            }
        },
 :
  etc

#Examples of how to configure the periods and schedules
#======================================================
#Create periods
#==============

# Start tagged instances at 9 am Monday in eu-west-2 only
$ scheduler-cli create-period --stack InstanceScheduler --name "Week-start-9am" --weekdays mon --begintime 09:00 --endtime 23:59 --region eu-west-2

# Stop tagged instances at 5 pm on Friday in eu-west-2 only
$ scheduler-cli create-period --stack InstanceScheduler --name "Week-end-5pm"   --weekdays fri --begintime 00:00 --endtime 17:00 --region eu-west-2

# Run tagged instances 1200-1300 Mon to Fri all regions
$ scheduler-cli create-period --stack InstanceScheduler --name "MyCore-Hours"   --weekdays mon-fri --begintime 12:00 --endtime 13:00

# Run tagged instances 1000-1100 Mon to Fri all regions
$ scheduler-cli update-period --stack InstanceScheduler --name "MyCore-Hours"   --weekdays mon-fri --begintime 10:00 --endtime 11:00

# Run tagged instances 0600-0700 on the first day of the month
$ scheduler-cli create-period --stack InstanceScheduler --name firstdayofmonth  --region eu-west-2 --begintime 06:00 --endtime 07:00 --monthdays 1

#Create Schedules
#================

$ scheduler-cli create-schedule --stack InstanceScheduler --name mon-9am-fri-5pm --periods mon-start-9am,tue-thu-full-day,fri-stop-5pm --timezone America/New_York
# n.b. For this to work this tag must be added to the instances "Schedule=mon-9am-fri-5pm"
# n.b. if you entered Sched as your tag name, your tag will be "Sched=mon-9am-fri-5pm"

$ scheduler-cli create-schedule --stack InstanceScheduler --name CoreHours --periods MyCore-Hours --timezone UTC

$ scheduler-cli create-schedule --stack InstanceScheduler --name dayone --region -west-2 --periods firstdayofmonth --timezone America/New_York

TO Test
=======
$ scheduler-cli create-period --stack InstanceScheduler --name "MyCore-Hours"   --weekdays mon-fri --begintime 12:00 --endtime 13:00
$ scheduler-cli create-schedule --stack InstanceScheduler --name CoreHours --periods MyCore-Hours --timezone UTC
Add the tag Name:Schedule, Value:CoreHours to an EC2 instance
Wait 5 minutes and the instance will stop 


#========================
#Cross Account Scheduling
#========================

This solution includes a template (instance-scheduler-remote) that creates the AWS Identity and Access Management (IAM) 
roles necessary to start and stop instances in secondary accounts. You can review and modify permissions in the remote 
template before you launch the stack.

To apply automated start-stop schedules to resources in secondary accounts, launch the main solution template 
(instance-scheduler) in the primary account. Then, launch the remote template (instance-scheduler-remote) in 
each applicable secondary account. When each remote stack is launched, it creates a cross-account role Amazon 
Resource Name (ARN). Update the main solution stack with each cross-account role ARN by entering the appropriate 
ARN(s) in the Cross-account roles parameter to allow the AWS Instance Scheduler to perform start and stop actions 
on instances in the secondary accounts.

#AWS Systems Manager Parameter Store
#-----------------------------------
The Instance Scheduler enables you to use AWS Systems Manager Parameter Store to store cross-account role ARNs. 
You can store cross-account ARNs as a list parameter where every item is an ARN, or as a string parameter that 
contains a comma-delimited list of ARNs. The parameter has the format {param:name} where the name is the name 
of the parameter in the parameter store.

To leverage this feature, you must launch the Instance Scheduler stack in the same account as your parameter store.
Connect to the Organisation account:
  $ aws configure (e.g. psa)

Create the Instance Scheduler stack in the organisation account
  $ aws cloudformation create-stack --stack-name InstanceScheduler --template-body file://instance-schedulerOrg.template --parameters file://StackParamsOrg.json --capabilities CAPABILITY_NAMED_IAM

Connect to the Sub account:
  $ aws configure (e.g.bd4)

Create the Instance Scheduler sub account stack
  $ aws cloudformation create-stack --stack-name InstanceScheduler --template-body file://instance-schedulerOrg-remote.template --parameters file://StackParamsOrg-remote.json --capabilities CAPABILITY_NAMED_IAM

  Make a note of the CrossAccountRole ARN

Connect to the Organisation account:
  $ aws configure (e.g. psa)
  
Update the organisation stack with the Cross Account Role ARN created in the sub account
  $ aws cloudformation update-stack --stack-name InstanceScheduler --template-body file://instance-schedulerOrg-remote.template --parameters 
   ParameterKey="CrossAccountRoles",ParameterValue="arn:aws:iam::780480840318:role/InstanceScheduler-EC2SchedulerCrossAccountRole-1MCYX7AD5QPG0" --capabilities CAPABILITY_NAMED_IAM

An error occurred (ValidationError) when calling the UpdateStack operation: Parameters: [InstanceSchedulerAccount] must have values

$ scheduler-cli create-period   --stack InstanceScheduler --name "MyCore-Hours"   --weekdays mon-fri --begintime 10:00 --endtime 11:00
$ scheduler-cli create-schedule --stack InstanceScheduler --name MyCoreHours      --periods MyCore-Hours --timezone UTC
In BD4 add the tag "OrgSchedule,MyCoreHours" to an EC2 instance
Wait 5 mins
The instance should be down.

Cohort Hours. Shutdown all instances at 18:00
$ scheduler-cli create-period --stack InstanceScheduler --name "stop-at-1800" --begintime 00:00 --endtime 18:00
$ scheduler-cli create-schedule --stack InstanceScheduler --name CohortHours --periods stop-at-1800
Tag all instances and RDS db's with "OrgSchedule,CohortHours"

#Automated Tagging
#=================
The Instance Scheduler can automatically add tags to all instances it starts or stops. You can specify a list of tag names or 
tagname=tagvalue pairs in the Started tags and Stopped tags parameters. The solution also includes macros that allow you to add 
variable information to the tags:
{scheduler}: The name of the scheduler stack
{year}: The year (four digits)
{month}: The month (two digits)
{day}: The day (two digits)
{hour}: The hour (two digits, 24-hour format)
{minute}: The minute (two digits)
{timezone}: The time zone
The following table gives examples of different inputs and the resulting tags.
Example Parameter Input	Instance Scheduler Tag
ScheduleMessage=Started by scheduler {scheduler}	                            ScheduleMessage=Started by scheduler MyScheduler
ScheduleMessage=Started on {year}/{month}/{day}                                 ScheduleMessage=Started on 2017/07/06
ScheduleMessage=Started on {year}/{month}/{day} at {hour}:{minute}	            ScheduleMessage=Started on 2017/07/06 at 09:00
ScheduleMessage=Started on {year}/{month}/{day} at {hour}:{minute} {timezone}	ScheduleMessage=Started on 2017/07/06 at 09:00 UTC
When you use the Started tags parameter, the tags are automatically deleted when the scheduler stops the instance. 
When you use the Stopped tags parameter, the tags are automatically deleted when the instance is started.

Encrypted Amazon EBS Volumes
============================
If your Amazon EC2 instances contain encrypted Amazon Elastic Block Store (Amazon EBS) volumes, 
you must grant the Instance Scheduler permission to use the customer master key (CMK) to start 
and stop instances. Add the kms:CreateGrant permission to the Instance Scheduler role 
(<stackname>-SchedulerRole-<id>).

Logging and Notifications
=========================
The Instance Scheduler leverages Amazon CloudWatch Logs for logging. 
Warning and error messages are also published to a solution-created Amazon SNS topic which sends 
messages to a subscribed email address.

Review the parameters for the template, and modify them as necessary.
=====================================================================
This solution uses the following default values.

Instance Scheduler tag name - Schedule - This tag identifies instances to receive automated actions, 
  and also allows for custom start-stop parameters.
Service(s) to schedule- EC2 - The services to schedule. Select EC2, RDS, or Both.
Schedule Aurora Clusters - No - Choose whether to schedule Amazon Aurora clusters. To enable Aurora cluster scheduling, 
  you must select RDS or Both for the Service(s) to schedule parameter.
Create RDS instance snapshot - Yes - Choose whether to create a snapshot before stopping RDS instances
Scheduling enabled - Yes - Select No to temporarily disable scheduling.
Region(s) - <Optional input> - List of regions where instances will be scheduled. For example, us-east-1, us-west-1.
Default time zone - UTC - Default time zone for schedules. For a list of acceptable time zone values, see the TZ column 
  of the List of TZ Database Time Zones.
Cross-account roles - <Optional input> - Comma-delimited list of cross-account roles. 
  For example, arn:aws:iam::111122223333:role/<stackname>SchedulerCrossAccountRole. 
  If you store your cross-account ARNs in the AWS Systems Manager Parameter Store, use the format {param:name}.
Enter the secondary account CrossAccountRoleArn value(s) in this parameter.

This account - Yes - Select Yes to allow the task to select resources in this account. Note If you set this parameter to No, 
  you must configure cross-account roles.
Frequency - 5 - The frequency in minutes at which the AWS Lambda function runs. Select 1, 2, 5, 10, 15, 30, or 60.
Enable CloudWatch Metrics - No - Choose whether to collect data using CloudWatch Metrics for all schedules. You can override 
  this default setting for an individual schedule when you configure it (see Step 3).
Memory Size - 128 - The memory size of the solution’s main AWS Lambda function. Increase the default size to schedule a large 
  number of Amazon EC2 and Amazon RDS instances.
Enable CloudWatch Logs - No - Choose whether to log detailed information in CloudWatch Logs.
Log retention days - 30 - The log retention period in days
Started tags - <Optional input> - Tags to add to started instances. Use a list of tagname=tagvalue pairs.
Stopped tags - <Optional input> - Tags to add to stopped instances. Use a list of tagname=tagvalue pairs.
Send anonymous usage data - Yes - Send anonymous data to AWS to help us understand solution usage and related cost savings 
  across our customer base as a whole. To opt out of this feature, select No. For more information, see the Appendix F.

Tag Your Instances
==================
When you deployed the AWS CloudFormation template, you defined the name (tag key) for the solution’s custom tag. 
For the Instance Scheduler to recognize an Amazon EC2 or Amazon RDS instance, the tag key on that instance must 
match the custom tag name stored in the Amazon DynamoDB table.

# These instructions and code were generated from:
#
# AWS Instance Scheduler documentation
# https://aws.amazon.com/solutions/implementations/instance-scheduler/
# https://aws.amazon.com/premiumsupport/knowledge-center/stop-start-instance-scheduler/
#
# AWS Instance Scheduler Template locations
# https://s3.eu-west-2.amazonaws.com/cf-templates-17un5cz3tvua5-eu-west-2/2020183trV-Schedule1
# https://s3-external-1.amazonaws.com/cf-templates-17un5cz3tvua5-us-east-1/2020183I9A-Schedule1

