tfp="azurerm_virtual_network"
prefix="vnet"
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
azr=`az network vnet list -g $rgsource`
#
# loop around vnets
#
count=`echo $azr | jq '. | length'`
count=`expr $count - 1`
for i in `seq 0 $count`; do
name=`echo $azr | jq '.[(${i})].name' | tr -d '"' `
id=`echo $azr | jq '.[(${i})].id' | tr -d '"'`
addsp=`echo $azr | jq '.[i(${i})].addressSpace.addressPrefixes[0]'`
printf "resource \"%s\" \"%s\" { \n" $tfp $name > $prefix-$name.tf
printf "\tname = \"%s\"\n" $name >> $prefix-$name.tf
printf "\t location = \"\${var.loctarget}\"\n" >> $prefix-$name.tf
printf "\t resource_group_name = \"\${var.rgtarget}\"\n"  >> $prefix-$name.tf
#
# need to loop around prefixes
#
printf "\taddress_space = [%s]\n" $addsp >> $prefix-$name.tf
#
#loop around subnets
#
subs=`echo $azr | jq '.subnets'`
count=`echo $subs | jq '. | length'`
count=`expr $count - 1`
for j in `seq 0 $count`; do
snname=`echo $subs | jq '.[(${j})].name'`
snaddr=`echo $subs | jq '.[i(${j})].addressPrefix'`
snnsgid=`echo $subs | jq '.[i(${j})].networkSecurityGroup.id'`
nsgnam=`echo $snnsgid | cut -d'/' -f9 | tr -d '"'`
printf "\tsubnet {\n"  >> $prefix-$name.tf
printf "\t\t name = %s\n" $snname >> $prefix-$name.tf
printf "\t\t address_prefix = %s\n" $snaddr >> $prefix-$name.tf
printf "\t\t security_group = \"\${azurerm_network_security_group.%s.id}\"\n" $nsgnam >> $prefix-$name.tf
printf "\t}\n" >> $prefix-$name.tf
echo "}" >> $prefix-$name.tf
done
#
#
cat $prefix-$name.tf
terraform state rm $tfp.$name
terraform import $tfp.$name $id
done
