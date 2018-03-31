tfp="azurerm_subnet"
prefixa="sub"
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
#
#
vnets=`az network vnet list -g $rgsource`
count=`echo $vnets | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for j in `seq 0 $count`; do
        vname=`echo $vnets | jq ".[(${j})].name" | tr -d '"'`
        echo $vname
        #
        azr=`az network vnet subnet list -g $rgsource --vnet-name $vname`
        scount=`echo $azr | jq '. | length'`
        scount=`expr $scount - 1`
        for i in `seq 0 $scount`; do
            name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
            id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
            rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
            prefix=`printf "%s_%s" $rg $prefixa`
            sprefix=`echo $azr | jq ".[(${i})].addressPrefix" | tr -d '"'`
            snsg=`echo $azr | jq ".[(${i})].networkSecurityGroup.id" | cut -f9 -d"/" | tr -d '"'`
            printf "resource \"%s\" \"%s\" {\n" $tfp $name > $prefix-$name.tf
            printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
            printf "\t virtual_network_name = \"%s\"\n" $vname >> $prefix-$name.tf
            printf "\t address_prefix = \"%s\"\n" $sprefix >> $prefix-$name.tf
            #printf "\t resource_group_name = \"\${var.rgtarget}\"\n" >> $prefix-$name.tf
            printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
            if [ "$snsg" != "null" ]; then
                printf "\t network_security_group_id = \"\${azurerm_network_security_group.%s.id}\"\n" $snsg >> $prefix-$name.tf
            fi
            printf "}\n" >> $prefix-$name.tf
            cat $prefix-$name.tf
            terraform state rm $tfp.$name
            terraform import $tfp.$name $id
        done
    done
fi
