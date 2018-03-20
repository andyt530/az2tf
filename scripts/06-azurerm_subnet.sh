tfp="azurerm_subnet"
prefix="sub"
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
#
vnets=`az network vnet list -g $rgsource`
count=`echo $vnets | jq '. | length'`
count=`expr $count - 1`
for j in `seq 0 $count`; do
vname=`echo $vnets | jq ".[(${i})].name" | tr -d '"'`
#
azr=`az network vnet subnet list -g $rgsource --vnet-name $vname`
scount=`echo $azr | jq '. | length'`
scount=`expr $scount - 1`
for i in `seq 0 $scount`; do
name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
sprefix=`echo $azr | jq ".[(${i})].addressPrefix" | tr -d '"'`
snsg=`echo $azr | jq ".[(${i})].networkSecurityGroup.id" | cut -f9 -d"/" | tr -d '"'`
printf "resource \"%s\" \"%s\" {\n" $ftp $name > $prefix-$name.tf
printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
printf "\t virtual_network_name = \"%s\"\n" $vname >> $prefix-$name.tf
printf "\t address_prefix = \"%s\"\n" $sprefix >> $prefix-$name.tf
printf "\t resource_group_name = \"\${var.rgtarget}\"\n" >> $prefix-$name.tf
printf "\t network_security_group_id = \"\${azurerm_network_security_group.%s.id}\"\n" $snsg >> $prefix-$name.tf
printf "}\n" >> $prefix-$name.tf
cat $prefix-$name.tf
terraform state rm $tfp.$name
terraform import $tfp.$name $sid
done
done
