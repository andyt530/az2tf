# az2tf

If you've found this via a search - IT IS STILL UNDER DEVELOPMENT

This utility 'Azure to Terraform' (az2tf) 
reads an Azure Subscription and generates all the required terraform configuration files (.tf) from each of the composite Azure Resource Groups
It also imports the terraform state using a

"terraform import ...." command

And finally runs a 

"terraform plan ."  command 

There should hopefully be no subsequent additions or deletions reported by the terraform plan command as all the approriate terraform configuration files will have have automatically been created.

## Supported Resource Types

The following terraform resource types are supported by this tool at this time:

* azurerm_role_definition (subscription level)
* azurerm_role_assignment (subscription level)
* azurerm_policy_definition (custom poicies only)
* azurerm_policy_assignment

* azurerm_resource_group (full)
* azurerm_route_table (full)
* azurerm_availability_set (full)
* azurerm_subnet (full)
* azurerm_virtual_network (full)
* azurerm_virtual_network_peering (full)
* azurerm_network_security_group (full)
* azurerm_managed_disk  (Common)
* azurerm_storage_account (Common - tf full support lacking)
* azurerm_public_ip  (Common- tf import issues)
* azurerm_network_interface  (Common)
* azurerm_local_network_gateway
* azurerm_virtual_network_gateway
* azurerm_virtual_network_gateway_connection
* azurerm_express_route_circuit (full)
* azurerm_express_route_circuit_authorization (full)
* azurerm_express_route_circuit_peering (partial)

* azurerm_virtual_machine  (Common)
* azurerm_key_vault (Common)
* azurerm_management_lock  (full)
* azurerm_automation_account
* azurerm_lb  (full)
* azurerm_lb_backend_address_pool (full)
* azurerm_lb_rule (full)
* azurerm_lb_probe (full)

* azurerm_container_registry (full)
* azurerm_kubernetes_cluster
* azurerm_recovery_services_vault (full)
* azurerm_log_analytics_workspace (full)
* azurerm_log_analytics_solution (partial)

In progress ..

* azure_nat_rule (full - needs more testing)
* azure_nat_pool (full - needs more testing)

(Full) = full support for all terraform attributes
(Common) = support for the most Common terraform attributes
(Partial) = support for some of the terraform attributes

## Requirements & Prerequisites
+ The tool is written for the bash shell script and has been tested on a MAC
+ Azure cli2 **version 2.0.31 or higher** needs to be installed and you need a login with at least "Read" priviledges
+ terraform needs to be installed


## Quickstart guide to using the tool

Running the tool required these steps:
1. Unzip or clone this git repo into an empty directory
1. login to the Azure cli2  (az login)
1. run the tool giving the ID of a subscription as a paremeter  ./az2tf.sh  Your-subscription-ID 

Be patient - lots of output is given as az2tf:

+ Loops for each provider through your resource groups &
+ Creates the requited *.tf configuration files
+ Performs the necessary 'terraform import' commands
+ And finally runs a 'terraform plan'

For smaller tests where all resources are contained in a single Resource Group run 

./az2tf.sh Your-subscription-ID  RG-Name


## Planned Additions

+ Load Balancers (deeper support)
+ Storage containers with storage firewall rules
+ AKS
+ Other terraform providers where terraform & Azure cli2 mutually support

## Known problems

### Speed

It is quite slow to loop around everything in large subscriptions, there are ways to speed this tool up (make fewer az cli command calls) but it would also make it harder to debug, I may look at doing this after I finish building out support for more providers.

### KeyVault:

Can fail if your login/SPN doesn't have acccess to the KeyVault

### Virtual machines:
These attributes always get reported in terraform plan set to false by default  - may need to manually override

+ delete_data_disks_on_termination:           "" => "false"
+ delete_os_disk_on_termination:              "" => "false"


### Storage Account

awaiting terraform support for VNet service endpoints/firewalling

Can fail if your login/SPN doesn't have acccess the KeyVault used for encryption

### OMS

Not all OMS solutions can be imported (naming issues with Azure)

### ExpressRoute

No support for MS peering (don't have one to test!)


### Key Vault

terraform doesn't support Backup and Restore as certificate permissions