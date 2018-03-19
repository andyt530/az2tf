echo "azurerm_subnet"
source ./setup-vars.sh
rgsource="rg-Packer1"
myrg="rg-Packer1"
#az account set -s $ARM_SUBSCRIPTION_ID
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
#
#
vnets=`az network vnet list -g $rgsource`
count=`echo $vnets | jq '. | length'`
count=`expr $count - 1`
for j in `seq 0 $count`; do
comm="echo"' $vnets'" | jq '.[$j].name'"
vname=`eval $comm | tr -d '"'`
echo $vname
#
subs=`az network vnet subnet list -g $rgsource --vnet-name $vname`
scount=`echo $subs | jq '. | length'`
scount=`expr $scount - 1`
for i in `seq 0 $scount`; do
comm="echo"' $subs'" | jq '.[$i].name'"
sname=`eval $comm | tr -d '"'`
comm="echo"' $subs'" | jq '.[$i].addressPrefix'"
sprefix=`eval $comm | tr -d '"'`
comm="echo"' $subs'" | jq '.[$i].networkSecurityGroup.id'"
snsg=`eval $comm | cut -f9 -d"/" | tr -d '"'`
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
comm="echo"' $vnets'" | jq '.[$j].name'"
vname=`eval $comm | tr -d '"'`
#echo $vname
#
subs=`az network vnet subnet list -g $rgsource --vnet-name $vname`
scount=`echo $subs | jq '. | length'`
scount=`expr $scount - 1`
for i in `seq 0 $scount`; do
comm="echo"' $subs'" | jq '.[$i].name'"
sname=`eval $comm | tr -d '"'`
comm="echo"' $subs'" | jq '.[$i].id'"
sid=`eval $comm | tr -d '"'`
terraform state rm azurerm_subnet.$sname
terraform import azurerm_subnet.$sname $sid
done
done
