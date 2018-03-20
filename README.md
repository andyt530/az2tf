# az2tf

Reads an Azure Resource Group and generates all the required terraform files
Imports the terraform state (terraform import)

A subsequent terraform plan .  should report no changes required as the automatically generated terraform configuration files should match the terraform state
