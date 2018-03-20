tfp="azurerm_public_ip"
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
pip=`az network public-ip list -g $rgsource`
count=`echo $pip | jq '. | length'`
count=`expr $count - 1`
for i in `seq 0 $count`; do
#echo $i
comm="echo"' $pip'" | jq '.[$i].name'"
pipname=`eval $comm | tr -d '"'`
comm="echo"' $pip'" | jq '.[$i].publicIpAllocationMethod'"
subipalloc=`eval $comm | tr -d '"'`
comm="echo"' $pip'" | jq '.[$i].networkSecurityGroup.id'"
snsg=`eval $comm | cut -d'/' -f9 | tr -d '"'`
#echo $pipname
printf "resource \"azurerm_public_ip\" \"%s\" {\n" $pipname > pip-$pipname.tf
printf "\t name = \"%s\"\n" $pipname >> pip-$pipname.tf
printf "\t location = \"\${var.loctarget}\"\n" >> pip-$pipname.tf
printf "\t resource_group_name = \"\${var.rgtarget}\"\n" >> pip-$pipname.tf
printf "\t public_ip_address_allocation = \"%s\" \n"  $subipalloc >> pip-$pipname.tf
#
printf "}\n" >> pip-$pipname.tf
#
cat pip-$pipname.tf
done
for i in `seq 0 $count`; do
comm="echo"' $pip'" | jq '.[$i].id'"
pipid=`eval $comm | tr -d '"'`
comm="echo"' $pip'" | jq '.[$i].name'"
pipname=`eval $comm | tr -d '"'`
#echo $pipid
terraform state rm $tfp.$pipname 
terraform import $tfp.$pipname $pipid
done
