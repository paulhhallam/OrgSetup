# PSAOrgSetup

These scripts will:

	1) Create an organisation sub account

	2) Set up the instance scheduler to reduce costs across the organisation

#
## CreateSubAccount
#
The terraform script in this folder can be executed to create a new organisation sub account for a Cohort

The script requires 

	1) The new account root email address
		This is normally the same email address for all accounts.

	2) The name for the new account
		e.g. A5

Once we move to AWS Control Tower (CT) these instructions will be replaced but we are waiting for AWS to configure CT in EU-WEST-2 (London)

#
## OrganisationInstanceScheduler
#
The scripts inside this directory will set up the instance scheduler that runs from the organisation account but will execute on each of the sub accounts.

Please note that a script must be run on each sub account (this is managed under the code in the repository "CohortSetup/PSACohortInstanceScheduler/")

The ouput from the sub account instance scheduler setup will need to be added to the DynamoDB table created by this Organisation Instance Scheduler code.

Instructions are in the relevant README files.
