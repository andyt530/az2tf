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
azr=`az network vpn-connection list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        loc=`echo $azr | jq ".[(${i})].location" | tr -d '"'`
        type=`echo $azr | jq ".[(${i})].connectionType" | tr -d '"'`
        vngrg=`echo $azr | jq ".[(${i})].virtualNetworkGateway1.id" | cut -d'/' -f5 | tr -d '"'`
        vngnam=`echo $azr | jq ".[(${i})].virtualNetworkGateway1.id" | cut -d'/' -f9 | tr -d '"'`
        echo
        peerrg=`echo $azr | jq ".[(${i})].peer.id" | cut -d'/' -f5 | tr -d '"'`
        peernam=`echo $azr | jq ".[(${i})].peer.id" | cut -d'/' -f9 | tr -d '"'`
        
        if [ "$type" = "IPsec" ]; then
            echo "is sec"
            peerrg=`echo $azr | jq ".[(${i})].localNetworkGateway2.id" | cut -d'/' -f5 | tr -d '"'`
            peernam=`echo $azr | jq ".[(${i})].localNetworkGateway2.id" | cut -d'/' -f9 | tr -d '"'`
            echo $peerrg
            echo $peernam
        fi
        
        
        authkey=`echo $azr | jq ".[(${i})].authorizationKey" | tr -d '"'`
        enbgp=`echo $azr | jq ".[(${i})].enableBgp" | tr -d '"'`
        rw=`echo $azr | jq ".[(${i})].routingWeight" | tr -d '"'`
        echo "RW = $rw"
        sk=`echo $azr | jq ".[(${i})].shared_key" | tr -d '"'`
        pbs=`echo $azr | jq ".[(${i})].usePolicyBasedTrafficSelectors" | tr -d '"'`
        
        prefix=`printf "%s__%s" $prefixa $rg`
        
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name > $prefix-$name.tf
        printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
        printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
        printf "\t location = \"%s\"\n" $loc >> $prefix-$name.tf
        printf "\t type = \"%s\"\n" $type >> $prefix-$name.tf
        printf "\t\t virtual_network_gateway_id = \"\${azurerm_virtual_network_gateway.%s__%s.id}\"\n" $vngrg $vngnam >> $prefix-$name.tf
        if [ "$authkey" -ne "null" ]; then
            printf "\t authorization_key = \"%s\"\n" $authkey >> $prefix-$name.tf
        fi
        
        printf "\t enable_bgp = \"%s\"\n" $enbgp >> $prefix-$name.tf
        if [ "$rw" != "null" ] && [ "$rw" != "0" ]; then
            printf "\t routing_weight = \"%s\"\n" $rw >> $prefix-$name.tf
        fi
        if [ "$sk" != "null" ]; then
            printf "\t shared_key = \"%s\"\n" $sk >> $prefix-$name.tf
        fi
        printf "\t use_policy_based_traffic_selectors = \"%s\"\n" $pbs >> $prefix-$name.tf
        echo $type
        if [ "$type" == "ExpressRoute" ]; then
            peerid=`echo $azr | jq ".[(${i})].peer.id" | tr -d '"'`
            printf "\t\t express_route_circuit_id = \"%s\"\n" $peerid >> $prefix-$name.tf
            #printf "\t\t express_route_circuit_id = \"\${azurerm_virtual_network_gateway.%s__%s.id}\"\n" $peerrg $peernam >> $prefix-$name.tf
            peerid=`echo $azr | jq ".[(${i})].peer.id" | tr -d '"'`
            
        fi
        if [ "$type" == "Vnet2Vnet" ]; then
            printf "\t\t peer_virtual_network_gateway_id = \"\${azurerm_virtual_network_gateway.%s__%s.id}\"\n" $peerrg $peernam >> $prefix-$name.tf
        fi
        if [ "$type" == "IPsec" ]; then
            printf "\t\t local_network_gateway_id = \"\${azurerm_local_network_gateway.%s__%s.id}\"\n" $peerrg $peernam >> $prefix-$name.tf
        fi
        
        
        ipsec=`echo $azr | jq ".[(${i})].ipsecPolicies"`
        jcount=`echo $ipsec | jq '. | length'`
        if [ "$jcount" -gt "0" ]; then
            jcount=`expr $jcount - 1`
            for j in `seq 0 $jcount`; do
                printf "\t ipsec_policy {\n" >> $prefix-$name.tf
                
                dhg=`echo $ipsec | jq ".[(${j})].dhGroup"`
                printf "\t dh_group {\n" $dhg >> $prefix-$name.tf
                
                printf "\t}\n" >> $prefix-$name.tf
            done
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
