tfp="azurerm_resource_group"
prefix="rg"
echo $tfp
rgsource=""
if [ "$1" != "" ]; then
rgsource=$1
else
echo -n "Enter name of Resource Group [$rgsource] > "
read response
if [ -n "$response" ]; then
     rgsource=$response
fi
fi
azr=`az group show -n $rgsource`
id=`echo $azr | jq '.id' | tr -d '"'`
printf "resource \"%s\" \"%s\" {"  > $tfp ${var.rgtarget} $prefix-${var.rgtarget}.tf
printf "\t name = \"\${var.rgtarget}\"\n" >> $prefix-${var.rgtarget}.tf
printf "\t location = \"\${var.loctarget}\"\n" >> $prefix-${var.rgtarget}.tf
echo "}" >> $prefix-${var.rgtarget}.tf
cat $prefix-${var.rgtarget}.tf
#
terraform state rm  $tfp.$rgsource 
terraform import $tfp.$rgsource $rgid
#
