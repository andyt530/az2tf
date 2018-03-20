tfp="azurerm_virtual_network"
echo $tfp
if [ "$1" != "" ]; then
rgsource=$1
else
echo -n "Enter name of Resource Group [$rgsource] > "
read response
if [ -n "$response" ]; then
     rgsource=$response
fi
fi
#
net=`az network vnet list -g $rgsource`
#
# loop around vnets
#
count=`echo $net | jq '. | length'`
count=`expr $count - 1`
for i in `seq 0 $count`; do
vname=`echo $net | jq '.[(${i})].name' | tr -d '"' `
vnid=`echo $net | jq '.[(${i})].id' | tr -d '"'`
addsp=`echo $net | jq '.[i(${i})].addressSpace.addressPrefixes[0]'`
printf "resource \"%s\" \"%s\" { \n" $tfp $vname > vnet-$vname.tf
printf "\tname = \"%s\"\n" $vname >> vnet-$vname.tf
printf "\t location = \"\${var.loctarget}\"\n" >> vnet-$vname.tf
printf "\t resource_group_name = \"\${var.rgtarget}\"\n"  >> vnet-$vname.tf
#
# need to loop around prefixes
#
printf "\taddress_space = [%s]\n" $addsp >> vnet-$vname.tf
#
#loop around subnets
#
subs=`echo $net | jq '.subnets'`
count=`echo $subs | jq '. | length'`
count=`expr $count - 1`
for j in `seq 0 $count`; do
snname=`echo $net | jq '.[(${j})].name'`
snaddr=`echo $net | jq '.[i(${j})].addressPrefix'`
snnsgid=`echo $net | jq '.[i(${j})].networkSecurityGroup.id'`
nsgnam=`echo $snnsgid | cut -d'/' -f9 | tr -d '"'`
printf "\tsubnet {\n"  >> vnet-$vname.tf
printf "\t\t name = %s\n" $snname >> vnet-$vname.tf
printf "\t\t address_prefix = %s\n" $snaddr >> vnet-$vname.tf
printf "\t\t security_group = \"\${azurerm_network_security_group.%s.id}\"\n" $nsgnam >> vnet-$vname.tf
printf "\t}\n" >> vnet-$vname.tf
echo "}" >> vnet-$vname.tf
done
#
#
#cat vnet-$vname.tf
done
terraform state rm $tfp.$vname
terraform import $tfp.$vname $vnid
