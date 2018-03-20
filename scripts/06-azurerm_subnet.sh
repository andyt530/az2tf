tfp="azurerm_subnet"
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
subs=`az network vnet subnet list -g $rgsource --vnet-name $vname`
scount=`echo $subs | jq '. | length'`
scount=`expr $scount - 1`
for i in `seq 0 $scount`; do
sname=`echo $subs | jq ".[(${i})].name" | tr -d '"'`
sprefix=`echo $subs | jq ".[(${i})].addressPrefix" | tr -d '"'`
snsg=`echo $subs | jq ".[(${i})].networkSecurityGroup.id" | cut -f9 -d"/" | tr -d '"'`
printf "resource \"azurerm_subnet\" \"%s\" {\n" $sname > sub-$sname.tf
printf "\t name = \"%s\"\n" $sname >> sub-$sname.tf
printf "\t virtual_network_name = \"%s\"\n" $vname >> sub-$sname.tf
printf "\t address_prefix = \"%s\"\n" $sprefix >> sub-$sname.tf
printf "\t resource_group_name = \"\${var.rgtarget}\"\n" >> sub-$sname.tf
printf "\t network_security_group_id = \"\${azurerm_network_security_group.%s.id}\"\n" $snsg >> sub-$sname.tf
printf "}\n" >> sub-$sname.tf
#cat sub-$sname.tf
done
done
count=`echo $vnets | jq '. | length'`
count=`expr $count - 1`
for j in `seq 0 $count`; do
vname=`echo $vnets | jq ".[(${i})].name" | tr -d '"'`
#
subs=`az network vnet subnet list -g $rgsource --vnet-name $vname`
scount=`echo $subs | jq '. | length'`
scount=`expr $scount - 1`
for i in `seq 0 $scount`; do
sname=`echo $subs | jq ".[(${i})].name" | tr -d '"'`
sid=`echo $subs | jq ".[(${i})].id" | tr -d '"'`
terraform state rm $tfp.$sname
terraform import $tfp.$sname $sid
done
done
