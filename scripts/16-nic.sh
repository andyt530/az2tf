myrg="nic-"
if [ "$1" != "" ]; then
rgsource=$1
else
echo -n "Enter name of Resource Group [$rgsource] > "
read response
if [ -n "$response" ]; then
     rgsource=$response
fi
fi
nic=`az network nic list -g $rgsource`
count=`echo $nic | jq '. | length'`
count=`expr $count - 1`
for i in `seq 0 $count`; do
#echo $i
comm="echo"' $nic'" | jq '.[$i].name'"
nicname=`eval $comm | tr -d '"'`
comm="echo"' $nic'" | jq '.[$i].ipConfigurations[0].privateIpAllocationMethod'"
subipalloc=`eval $comm | tr -d '"'`
comm="echo"' $nic'" | jq '.[$i].ipConfigurations[0].subnet.id'"
subname=`eval $comm | cut -d'/' -f11 | tr -d '"'`

echo $nicname
printf "resource \"azurerm_network_interface\" \"%s\" {\n" $nicname > $myrg-$nicname.tf
printf "\t name = \"%s\"\n" $nicname >> $myrg-$nicname.tf
printf "\t location = \"\${var.loctarget}\"\n" >> $myrg-$nicname.tf
printf "\t resource_group_name = \"\${var.rgtarget}\"\n" >> $myrg-$nicname.tf
printf "\t ip_configuration {\n" >> $myrg-$nicname.tf
printf "\t\t name = \"%s\" \n"  "ipconfig1" >> $myrg-$nicname.tf
printf "\t\t subnet_id = \"\${azurerm_subnet.%s.id}\" \n"  $subname >> $myrg-$nicname.tf
printf "\t\t private_ip_address_allocation = \"%s\" \n"  $subipalloc >> $myrg-$nicname.tf
printf "\t}\n" >> $myrg-$nicname.tf
#
printf "}\n" >> $myrg-$nicname.tf
#
cat $myrg-$nicname.tf
done
for i in `seq 0 $count`; do
comm="echo"' $nic'" | jq '.[$i].id'"
nicid=`eval $comm | tr -d '"'`
comm="echo"' $nic'" | jq '.[$i].name'"
nicname=`eval $comm | tr -d '"'`
echo $nicid
terraform state rm azurerm_network_interface.$nicname 
terraform import azurerm_network_interface.$nicname $nicid
done
