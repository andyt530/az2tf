tfp="azurerm_virtual_network_gateway"
prefixa="vng"
if [ "$1" != "" ]; then
    rgsource=$1
else
    echo -n "Enter name of Resource Group [$rgsource] > "
    read response
    if [ -n "$response" ]; then
        rgsource=$response
    fi
fi
azr=`az network vnet-gateway list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        loc=`echo $azr | jq ".[(${i})].location" | tr -d '"'`
        type=`echo $azr | jq ".[(${i})].gatewayType" | tr -d '"'`
        vpntype=`echo $azr | jq ".[(${i})].vpnType" | tr -d '"'`
        bgps=`echo $azr | jq ".[(${i})].bgpSettings" | tr -d '"'`
        sku=`echo $azr | jq ".[(${i})].sku.name" | tr -d '"'`
        vadsp=`echo $azr | jq ".[(${i})].vpnClientConfiguration.vpnClientAddressPool.addressPrefixes"`
        radsa=`echo $azr | jq ".[(${i})].vpnClientConfiguration.radiusServerAddress"`
        radss=`echo $azr | jq ".[(${i})].vpnClientConfiguration.radiusServerSecret"`
        vcp0=`echo $azr | jq ".[(${i})].vpnClientConfiguration.vpnClientProtocols[0]"`
        vcp=`echo $azr | jq ".[(${i})].vpnClientConfiguration.vpnClientProtocols"`
        
        
        aa=`echo $azr | jq ".[(${i})].activeActive"`
        enbgp=`echo $azr | jq ".[(${i})].enableBgp"`
        prefix=`printf "%s__%s" $prefixa $rg`
        
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name > $prefix-$name.tf
        printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
        printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
        printf "\t location = \"%s\"\n" $loc >> $prefix-$name.tf
        printf "\t type = \"%s\"\n" $type >> $prefix-$name.tf
        printf "\t vpn_type = \"%s\"\n" $vpntype >> $prefix-$name.tf
        printf "\t sku = \"%s\"\n" $sku >> $prefix-$name.tf
        printf "\t active_active = \"%s\"\n" $aa >> $prefix-$name.tf
        printf "\t enable_bgp = \"%s\"\n" $enbgp >> $prefix-$name.tf
        
        if [ "$vadsp" != "null" ]; then
            printf "\t vpn_client_configuration {\n"  >> $prefix-$name.tf
            printf "\t\t address_space = %s\n"  "$vadsp" >> $prefix-$name.tf
            if [ "$radsa" == "null" ]; then
                printf "\t\t root_certificate { \n"   >> $prefix-$name.tf
                printf "\t\t\t name = \"\"\n"   >> $prefix-$name.tf
                printf "\t\t\t public_cert_data = \"\"\n"   >> $prefix-$name.tf
                printf "\t\t }\n"  >> $prefix-$name.tf
            fi
            if [ "$radsa" != "null" ]; then
            printf "\t\t radius_server_address = %s\n"  "$radsa" >> $prefix-$name.tf
            printf "\t\t radius_server_secret = %s\n"  "$radss" >> $prefix-$name.tf
            fi
            if [ "$vcp0" != "null" ]; then
            printf "\t\t vpn_client_protocols = %s\n"  "$vcp" >> $prefix-$name.tf
            fi
            
            printf "\t }\n"  >> $prefix-$name.tf
        fi
        
        
        if [ "$bgps" != "null" ]; then
            printf "\t bgp_settings {\n"  >> $prefix-$name.tf
            asn=`echo $azr | jq ".[(${i})].bgpSettings.asn" | tr -d '"'`
            peera=`echo $azr | jq ".[(${i})].bgpSettings.bgpPeeringAddress" | tr -d '"'`
            peerw=`echo $azr | jq ".[(${i})].bgpSettings.peerWeight" | tr -d '"'`
            printf "\t\t asn = \"%s\"\n" $asn >> $prefix-$name.tf
            printf "\t\t peering_address = \"%s\"\n" $peera >> $prefix-$name.tf
            printf "\t\t peer_weight = \"%s\"\n" $peerw >> $prefix-$name.tf
            printf "\t }\n"  >> $prefix-$name.tf
        fi
        
        ipc=`echo $azr | jq ".[(${i})].ipConfigurations"`
        count=`echo $ipc | jq '. | length'`
        count=`expr $count - 1`
        for j in `seq 0 $count`; do
            ipcname=`echo $ipc | jq ".[(${j})].name"`
            ipcpipa=`echo $ipc | jq ".[(${j})].privateIpAllocationMethod"`
            ipcpipid=`echo $ipc | jq ".[(${j})].publicIpAddress.id"`
            ipcsubid=`echo $ipc | jq ".[(${j})].subnet.id"`
            pipnam=`echo $ipcpipid | cut -d'/' -f9 | tr -d '"'`
            piprg=`echo $ipcpipid | cut -d'/' -f5 | tr -d '"'`
            subnam=`echo $ipcsubid | cut -d'/' -f11 | tr -d '"'`
            subrg=`echo $ipcsubid | cut -d'/' -f5 | tr -d '"'`
            printf "\tip_configuration {\n"  >> $prefix-$name.tf
            printf "\t\t name = %s\n" $ipcname >> $prefix-$name.tf
            printf "\t\t private_ip_address_allocation = %s\n" $ipcpipa >> $prefix-$name.tf
            if [ "$pipnam" != "null" ]; then
                printf "\t\t public_ip_address_id = \"\${azurerm_public_ip.%s__%s.id}\"\n" $piprg $pipnam >> $prefix-$name.tf
            fi
            if [ "$subnam" != "null" ]; then
                printf "\t\t subnet_id = \"\${azurerm_subnet.%s__%s.id}\"\n" $subrg $subnam >> $prefix-$name.tf
            fi
            printf "\t}\n" >> $prefix-$name.tf
        done
        
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
