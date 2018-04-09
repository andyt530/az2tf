# az2tf

If you've found this via a search - IT IS STILL UNDER DEVELOPMENT

This utility 'Azure to Terraform' (az2tf) 
reads an Azure Subscription and generates all the required terraform configuration files from each of the composite Azure Resource Groups
It also imports the terraform state using a

"terraform import ...." command

And finally runs a 

"terraform plan ."  command 

There should hopefully be no subsequent additions or deletions as all the approriate tarraform configuration files will have have automatically been created.

## Supported Resource Types

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

## Requirements & Prerequisites
The tool is written for the bash shell script and has been tested on a MAC
Azure cli2 needs to be installed and you need a login with at least "Read" priviledges
terrafrom needs to be installed


## Quickstart guide to using the tool

Running the tool required these steps:
1. Unzip or clone this git repo into an empty directory
1. login to the Azure cli2  (az login)
1. run 'terraform init'
1. Set the environent variable TF_loc_target
1. run the tool giving the id of a subscription as a paremeter  (./az2tf.sh  xxxx-xxxx-xxxx-xxxx-xxxxxx)


## Planned Additions

Further support for route tables
Support for KeyVaults
NSG rules
Load Balancers
storage containers / storage firewall rules
manage disks and storage disk encryption settings & source id



