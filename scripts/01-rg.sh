echo "azurerm_resource_group"
source ./setup-vars.sh
rgsource="rg-Packer1"
myrg="rg-Packer1"
rm terraform.*.backup
az account set -s $ARM_SUBSCRIPTION_ID
myrg="rg-Packer1"
if [ "$1" != "" ]; then
rgsource=$1
else
echo -n "Enter name of Resource Group [$rgsource] > "
read response
if [ -n "$response" ]; then
     rgsource=$response
fi
fi
mrg=`az group show -n $rgsource`
comm="echo"' $mrg'" | jq '.id'"
rgid=`eval $comm | tr -d '"'`
echo "resource "azurerm_resource_group" "$myrg" {" > rg-$myrg.tf
printf "\t name = \"\${var.rgtarget}\"\n" >> rg-$myrg.tf
printf "\t location = \"\${var.loctarget}\"\n" >> rg-$myrg.tf
echo "}" >> rg-$myrg.tf
#cat rg-$myrg.tf
#
terraform state rm  azurerm_resource_group.$rgsource 
terraform import azurerm_resource_group.$rgsource $rgid
#
