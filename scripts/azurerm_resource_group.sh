tfp="azurerm_resource_group"
prefixa="rg"
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
loc=`echo $azr | jq '.location' | tr -d '"'`
id=`echo $azr | jq '.id' | tr -d '"'`
rg=$name
prefix=`printf "%s_%s" $prefixa $rg`
printf "resource \"%s\" \"%s\" {\n"  $tfp $rg > $prefix.tf
printf "\t name = \"%s\"\n" $rg >> $prefix.tf
printf "\t location = \"%s\"\n" $loc >> $prefix.tf


#
# Tags block
#
tags=`echo $azr | jq ".tags"`
tt=`echo $tags | jq .`
tcount=`echo $tags | jq '. | length'`
if [ "$tcount" -gt "0" ]; then
    printf "\t tags { \n" >> $prefix-$name.tf
    tt=`echo $tags | jq .`
    for j in `seq 1 $tcount`; do
        atag=`echo $tt | cut -d',' -f$j | tr -d '{' | tr -d '}'`
        tkey=`echo $atag | cut -d':' -f1 | tr -d '"'`
        tval=`echo $atag | awk -F '": ' '{print $2}' | tr -d '"'`
        printf "\t\t%s = \"%s\" \n" $tkey $tval >> $prefix-$name.tf
        
    done
    printf "\t}\n" >> $prefix-$name.tf
fi




echo "}" >> $prefix.tf
cat $prefix.tf
#
terraform state rm  $tfp.$name
echo "terraform state rm  $tfp.$name" >> tf-staterm.sh
terraform import $tfp.$name $id
echo "erraform import $tfp.$name $id" >> tf-stateimp.sh
#
