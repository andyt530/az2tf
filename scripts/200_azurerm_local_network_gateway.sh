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
azr=`az network local-gateway list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        loc=`echo $azr | jq ".[(${i})].location" | tr -d '"'`
        gwaddr=`echo $azr | jq ".[(${i})].gatewayIpAddress" | tr -d '"'`
        addrpre=`echo $azr | jq ".[(${i})].localNetworkAddressSpace.addressPrefixes"`
        bgps=`echo $azr | jq ".[(${i})].bgpSettings" | tr -d '"'`
        prefix=`printf "%s__%s" $prefixa $rg`
        
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name > $prefix-$name.tf
        printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
        printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
        printf "\t location = \"%s\"\n" $loc >> $prefix-$name.tf
        printf "\t gateway_address = \"%s\"\n" $gwaddr >> $prefix-$name.tf
        printf "\t address_space = %s\n" "$addrpre" >> $prefix-$name.tf
    
        if [ "$bgps" != "null" ]; then
            asn=`echo $azr | jq ".[(${i})].bgpSettings.asn" | tr -d '"'`
            peera=`echo $azr | jq ".[(${i})].bgpSettings.bgpPeeringAddress" | tr -d '"'`
            peerw=`echo $azr | jq ".[(${i})].bgpSettings.peerWeight" | tr -d '"'`

            printf "\t bgp_settings {\n"  >> $prefix-$name.tf
            printf "\t\t asn = \"%s\"\n" $asn >> $prefix-$name.tf
            printf "\t\t bgp_peering_address = \"%s\"\n" $peera >> $prefix-$name.tf
            printf "\t\t peer_weight = \"%s\"\n" $peerw >> $prefix-$name.tf
            printf "\t }\n"  >> $prefix-$name.tf
        fi

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
