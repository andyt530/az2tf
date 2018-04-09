# az2tf

This utility Azure to Terraform (az2tf) 
Reads an Azure Subscription and generates all the required terraform configuration files from each of the composite Resource Groups
It also imports the terraform state using a

"terraform import ...." command

And finally runs a 

"terraform plan ."  command 

There should hopefully be no subsequent additions or deletions as all the approriate tarraform configuration files will have have automatically been created.

The following terraform resource types are supported by this tool at this time:

* azure_resource_group
* azure_availability_set
