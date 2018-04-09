# az2tf

This utility 'Azure to Terraform' (az2tf) 
reads an Azure Subscription and generates all the required terraform configuration files from each of the composite Azure Resource Groups
It also imports the terraform state using a

"terraform import ...." command

And finally runs a 

"terraform plan ."  command 

There should hopefully be no subsequent additions or deletions as all the approriate tarraform configuration files will have have automatically been created.

The following terraform resource types are supported by this tool at this time:

* azurerm_resource_group
* azurerm_route_table
* azurerm_availability_set
* azurerm_subnet
* azurerm_virtual_network
* azurerm_network_security_group
* azurerm_managed_disk
* azurerm_storage_account
* azurerm_public_ip
* azurerm_network_interface
* azurerm_virtual_machine
