tfp="azurerm_resource_group"
echo $tfp
rgsource="rg-Packer1"
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
mrg=`az group show -n $rgsource`
rgid=`echo $mrg | jq '.id' | tr -d '"'`
printf "resource \"%s\" \"%s\" {"  > $tfp $myrg rg-$myrg.tf
printf "\t name = \"\${var.rgtarget}\"\n" >> rg-$myrg.tf
printf "\t location = \"\${var.loctarget}\"\n" >> rg-$myrg.tf
echo "}" >> rg-$myrg.tf
#cat rg-$myrg.tf
#
terraform state rm  $tfp.$rgsource 
terraform import $tfp.$rgsource $rgid
#
