tfp="azurerm_availability_set"
prefix="avs"
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
azr=`az vm availability-set list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then 
count=`expr $count - 1`
for i in `seq 0 $count`; do
name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`

printf "resource \"%s\" \"%s\" {\n" $tfp $name > $prefix-$name.tf
printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
printf "\t location = \"\${var.loctarget}\"\n" >> $prefix-$name.tf
#printf "\t resource_group_name = \"\${var.rgtarget}\"\n" >> $prefix-$name.tf
printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
printf "}\n" >> $prefix-$name.tf
#
cat $prefix-$name.tf
terraform state rm $tfp.$name 
terraform import $tfp.$name $id
done
fi
