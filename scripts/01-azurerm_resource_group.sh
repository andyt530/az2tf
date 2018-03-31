tfp="azurerm_resource_group"
prefix="rg"
echo $tfp
echo $TF_VAR_rgtarget
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

name=`echo $azr | jq '.name' | tr -d '"'`
id=`echo $azr | jq '.id' | tr -d '"'`
rg=$name
printf "resource \"%s\" \"%s\" {\n"  $tfp $rg > $prefix-$TF_VAR_rgtarget.tf
printf "\t name = \"%s\"\n" $rg >> $prefix-$TF_VAR_rgtarget.tf
printf "\t location = \"\${var.loctarget}\"\n" >> $prefix-$TF_VAR_rgtarget.tf
echo "}" >> $prefix-$TF_VAR_rgtarget.tf
cat $prefix-$TF_VAR_rgtarget.tf
#
terraform state rm  $tfp.$name
terraform import $tfp.$name $id
#
