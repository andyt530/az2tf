tfp="azurerm_network_interface"
prefixa="nic"
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
azr=`az network nic list -g $rgsource`
count=`echo $azr | jq '. | length'`
count=`expr $count - 1`
for i in `seq 0 $count`; do
    name=`echo $azr | jq ".[(${i})].name" | tr -d '"' | awk '{print tolower($0)}'`
    rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`  
    id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`

    prefix=`printf "%s_%s" $prefixa $rg`

    printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name > $prefix-$name.tf
    printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
    printf "\t location = \"\${var.loctarget}\"\n" >> $prefix-$name.tf
    printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
    printf "}\n" >> $prefix-$name.tf
    #
    cat $prefix-$name.tf
    statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $name`
    eval $statecomm
    evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $name $id`
    eval $evalcomm
    
done
