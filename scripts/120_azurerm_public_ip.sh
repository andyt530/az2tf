prefixa=`echo $0 | awk -F 'azurerm_' '{print $2}' | awk -F '.sh' '{print $1}' `
tfp=`printf "azurerm_%s" $prefixa`
if [ "$1" != "" ]; then
    rgsource=$1
else
    echo -n "Enter name of Resource Group [$rgsource] > "
    read response
    if [ -n "$response" ]; then
        rgsource=$response
    fi
fi
azr=`az network public-ip list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        loc=`echo $azr | jq ".[(${i})].location" | tr -d '"'`
        sku=`echo $azr | jq ".[(${i})].sku.name" | tr -d '"'`
        timo=`echo $azr | jq ".[(${i})].idleTimeoutInMinutes" | tr -d '"'`
        dnsname=`echo $azr | jq ".[(${i})].dnsSettings.domainNameLabel" | tr -d '"'`
        dnsfqdn=`echo $azr | jq ".[(${i})].dnsSettings.fqdn" | tr -d '"'`

        prefix=`printf "%s__%s" $prefixa $rg`
        subipalloc=`echo $azr | jq ".[(${i})].publicIpAllocationMethod" | tr -d '"'`
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name > $prefix-$name.tf
        printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
        printf "\t location = \"%s\"\n" $loc >> $prefix-$name.tf

        printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
        printf "\t public_ip_address_allocation = \"%s\" \n"  $subipalloc >> $prefix-$name.tf
        if [ "$sku" != "null" ]; then
            printf "\t sku = \"%s\" \n"  $sku >> $prefix-$name.tf
        fi
        #printf "\t idle_timeout_in_minutes = \"%s\" \n"  $timo >> $prefix-$name.tf
        if [ "$dnsname" != "null" ]; then
        printf "\t domain_name_label = \"%s\"\n" $dnsname >> $prefix-$name.tf
        fi
        #

            #
            # New Tags block
            tags=`echo $azr | jq ".[(${i})].tags"`
            tt=`echo $tags | jq .`
            tcount=`echo $tags | jq '. | length'`
            if [ "$tcount" -gt "0" ]; then
                printf "\t tags { \n" >> $prefix-$name.tf
                tt=`echo $tags | jq .`
                keys=`echo $tags | jq 'keys'`
                tcount=`expr $tcount - 1`
                for j in `seq 0 $tcount`; do
                    k1=`echo $keys | jq ".[(${j})]"`
                    tval=`echo $tt | jq .$k1`
                    tkey=`echo $k1 | tr -d '"'`
                    printf "\t\t%s = %s \n" $tkey "$tval" >> $prefix-$name.tf
                done
                printf "\t}\n" >> $prefix-$name.tf
            fi

        printf "}\n" >> $prefix-$name.tf
        #
        cat $prefix-$name.tf
        statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $name`
        echo $statecomm >> tf-staterm.sh
        eval $statecomm
        evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $name $id`
        echo $evalcomm >> tf-stateimp.sh
        eval $evalcomm
    done
fi
