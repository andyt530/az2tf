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
echo $rgsource 
#
net=`az network vnet list -g $myrg`
vname=`echo $net | jq '.[].name' `
vnid=`echo $net | jq '.[].id' `
vnid=`echo $vnid | tr -d '"'` 
vnloc=`echo $net | jq '.[].location' `
snname=`echo $net | jq '.[].subnets[0].name'`
snaddr=`echo $net | jq '.[].subnets[0].addressPrefix'`
snnsgid=`echo $net | jq '.[].subnets[0].networkSecurityGroup.id'`
nsgnam=`echo $snnsgid | cut -d'/' -f9 | tr -d '"'`
vn=`echo $vname | tr -d '"'`
vl=`echo $vnloc | tr -d '"'`
addsp=`echo $net | jq '.[].addressSpace.addressPrefixes[0]'`
echo "resource "azurerm_virtual_network" "$vname" {" > vnet-$vn.tf
printf "\tname = \"%s\"\n" $vn >> vnet-$vn.tf
printf "\tlocation = \"%s\"\n" $vl >> vnet-$vn.tf
printf "\tresource_group_name = \"%s\"\n" $myrg >> vnet-$vn.tf
printf "\taddress_space = [%s]\n" $addsp >> vnet-$vn.tf
printf "\tsubnet {\n"  >> vnet-$vn.tf
printf "\t\t name = %s\n" $snname >> vnet-$vn.tf
printf "\t\t address_prefix = %s\n" $snaddr >> vnet-$vn.tf
printf "\t\t security_group = \"\${azurerm_network_security_group.%s.id}\"\n" $nsgnam >> vnet-$vn.tf
printf "\t}\n" >> vnet-$vn.tf
echo "}" >> vnet-$vn.tf
cat vnet-$vn.tf
terraform state rm azurerm_virtual_network.$vn
terraform import azurerm_virtual_network.$vn $vnid
