# az2tf

Reads an Azure Resource Group and generates all the required terraform configuration files and then imports the terraform state 

"terraform import ...."

A subsequent 

"terraform plan ."  

Should report no changes required as the automatically az2tf generated terraform configuration files should match the terraform import state.
