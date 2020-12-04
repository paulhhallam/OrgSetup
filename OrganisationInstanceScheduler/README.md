
More detailed instructions on the set up and AWS code used is included in the "More_README.md" file

These instructions will install the AWS instance scheduler as described in the AWS documentation.

The instance scheduler is controlled from the Organisation account; 

the cohort/sub account setup is completed in CohortSetup/PSACohortInstanceScheduler/

Download, extract and install the AWS scheduler cli
===================================================
Using the instructions in https://docs.aws.amazon.com/solutions/latest/instance-scheduler/appendix-a.html 

download the aws scheduler cli code

$ https://s3.amazonaws.com/solutions-reference/aws-instance-scheduler/latest/scheduler-cli.zip

$ unzip scheduler-cli.zip

$ cd .\scheduler-cli\

$ sudo python3 setup.py install

Instructions For the Organisation account
=========================================

set the AWS profile to your organisation account 

$ aws configure

Changes
=======
Each instance that will be scheduled should have Tags consisting of

	Key = "OrgSchedule", Value = "CohortHours"

These tags are automatically added to EC2 and RDS instances by the autotag code  run as part of the cohort setup.

To change the scheduler tag then edit StackParams.json and change "OrgSchedule" to your choice.

i.e. look for the following section in the file and modify.
        "TagName": {
            "Type": "String",
            "Default": "OrgSchedule",
            "MinLength": 1,
            "MaxLength": 127,
            "Description": "Name of tag to use for associating instance schedule schemas with service instances."
        },

