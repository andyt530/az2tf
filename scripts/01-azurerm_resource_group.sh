tfp="azurerm_resource_group"
prefixa="rg"
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
prefix=`printf "%s_%s" $prefixa $rg`
printf "resource \"%s\" \"%s\" {\n"  $tfp $rg > $prefix.tf
printf "\t name = \"%s\"\n" $rg >> $prefix.tf
printf "\t location = \"\${var.loctarget}\"\n" >> $prefix.tf
echo "}" >> $prefix.tf
cat $prefix.tf
#
terraform state rm  $tfp.$name
terraform import $tfp.$name $id
#
