# az2tf

If you've found this via a search - IT IS STILL UNDER DEVELOPMENT

This utility 'Azure to Terraform' (az2tf) 
reads an Azure Subscription and generates all the required terraform configuration files from each of the composite Azure Resource Groups
It also imports the terraform state using a

"terraform import ...." command

And finally runs a 

"terraform plan ."  command 

There should hopefully be no subsequent additions or deletions reported by the terraform plan command as all the approriate tarraform configuration files will have have automatically been created.

## Supported Resource Types

The following terraform resource types are supported by this tool at this time:

* azurerm_role_definition (subscription level)
* azurerm_role_assignment (subscription level)
* azurerm_policy_definition (custom)
* azurerm_policy_assignment

* azurerm_resource_group (full)
* azurerm_route_table
* azurerm_availability_set
* azurerm_subnet (full)
* azurerm_virtual_network
* azurerm_virtual_network_peering (full)
* azurerm_network_security_group
* azurerm_managed_disk
* azurerm_storage_account 
* azurerm_public_ip
* azurerm_network_interface
* azurerm_virtual_machine
* azurerm_key_vault (see known issue)
* azurerm_management_lock
* azurerm_lb (see known issue)
* azurerm_lb_backend_address_pool
* azurerm_lb_rule
* azurerm_lb_probe

In progress ..

* azure_nat_rule
* azure_nat_pool



## Requirements & Prerequisites
+ The tool is written for the bash shell script and has been tested on a MAC
+ Azure cli2 **version 2.0.31 or higher** needs to be installed and you need a login with at least "Read" priviledges
+ terraform needs to be installed


## Quickstart guide to using the tool

Running the tool required these steps:
1. Unzip or clone this git repo into an empty directory
1. login to the Azure cli2  (az login)
1. run the tool giving the ID of a subscription as a paremeter  ./az2tf.sh  Your-subscription-ID 

Or for smaller tests where all resources are contained in a single Resource Group run 

./az2tf.sh Your-subscription-ID  RG-Name


## Planned Additions

+ Load Balancers (deeper support)
+ Storage containers / storage firewall rules
+ ACR & AKS

## Know problems

### KeyVault:
certificate permissions are ignored due to terraform issue - awaiting azurerm 1.4.0 provider

Can fail if your login/SPN doesn't have acccess to the KeyVault

### Virtual machines:
These attributes always set to true - may need to manually override

delete_data_disks_on_termination:           "" => "true"

delete_os_disk_on_termination:              "" => "true"

### Load Balancer:

Terraform doesn't seem to pull through the LB's Frontend IP configuration during an import - issue logged

### Storage Account

awaiting terraform support for VNet service endpoints/firewalling

Can fail if your login/SPN doesn't have acccess the KeyVault used for encryption

###

OMS - terraform supports - but Azure cli2 doesn't as yet.
