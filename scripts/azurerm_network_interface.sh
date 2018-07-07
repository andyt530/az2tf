tfp="azurerm_network_interface"
prefixa="nic"
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
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        loc=`echo $azr | jq ".[(${i})].location" | tr -d '"'`
        ipfor=`echo $azr | jq ".[(${i})].enableIpForwarding" | tr -d '"'`
        netacc=`echo $azr | jq ".[(${i})].enableAcceleratedNetworking" | tr -d '"'`
        prefix=`printf "%s__%s" $prefixa $rg`
        snsg=`echo $azr | jq ".[(${i})].networkSecurityGroup.id" | cut -d'/' -f9 | tr -d '"'`
        snsgrg=`echo $azr | jq ".[(${i})].networkSecurityGroup.id" | cut -d'/' -f5 | tr -d '"'`
        ipcon=`echo $azr | jq ".[(${i})].ipConfigurations"`

        
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name > $prefix-$name.tf
        printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
        printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
        printf "\t location = \"%s\"\n" $loc >> $prefix-$name.tf
        if [ "$snsg" != "null" ]; then
            printf "\t network_security_group_id = \"\${azurerm_network_security_group.%s__%s.id}\"\n" $snsgrg $snsg >> $prefix-$name.tf
        fi
        
        #printf "\t internal_dns_name_label  = \"%s\"\n" $ipfor >> $prefix-$name.tf
        printf "\t enable_ip_forwarding = \"%s\"\n" $ipfor >> $prefix-$name.tf
        printf "\t enable_accelerated_networking  = \"%s\"\n" $netacc >> $prefix-$name.tf
        #printf "\t dns_servers  = \"%s\"\n" $ipfor >> $prefix-$name.tf
        privip0=`echo $azr | jq ".[(${i})].ipConfigurations[(0)].privateIpAddress" | tr -d '"'`
        
        

        
        icount=`echo $ipcon | jq '. | length'`
        if [ "$icount" -gt "0" ]; then
            icount=`expr $icount - 1`
            for j in `seq 0 $icount`; do
                ipcname=`echo $azr | jq ".[(${i})].ipConfigurations[(${j})].name" | cut -d'/' -f11 | tr -d '"'`
                subname=`echo $azr | jq ".[(${i})].ipConfigurations[(${j})].subnet.id" | cut -d'/' -f11 | tr -d '"'`
                subrg=`echo $azr | jq ".[(${i})].ipConfigurations[(${j})].subnet.id" | cut -d'/' -f5 | tr -d '"'`
                subipid=`echo $azr | jq ".[(${i})].ipConfigurations[(${j})].publicIpAddress.id" | cut -d'/' -f9 | tr -d '"'`
                subipalloc=`echo $azr | jq ".[(${i})].ipConfigurations[(${j})].privateIpAllocationMethod" | tr -d '"'`
                privip=`echo $azr | jq ".[(${i})].ipConfigurations[(${j})].privateIpAddress" | tr -d '"'`
                prim=`echo $azr | jq ".[(${i})].ipConfigurations[(${j})].primary" | tr -d '"'`
                pubipnam=`echo $azr | jq ".[(${i})].ipConfigurations[(${j})].publicIpAddress.id" | cut -d'/' -f9 | tr -d '"'`
                pubiprg=`echo $azr | jq ".[(${i})].ipConfigurations[(${j})].publicIpAddress.id" | cut -d'/' -f5 | tr -d '"'`



                printf "\t ip_configuration {\n" >> $prefix-$name.tf
                printf "\t\t name = \"%s\" \n"  $ipcname >> $prefix-$name.tf
                printf "\t\t subnet_id = \"\${azurerm_subnet.%s__%s.id}\"\n" $subrg $subname >> $prefix-$name.tf
                if [ "$subipalloc" != "Dynamic" ]; then
                    printf "\t\t private_ip_address = \"%s\" \n"  $privip >> $prefix-$name.tf
                fi
                printf "\t\t private_ip_address_allocation = \"%s\" \n"  $subipalloc >> $prefix-$name.tf
                if [ "$subipid" != "null" ]; then
                    printf "\t\t public_ip_address_id = \"\${azurerm_public_ip.%s__%s.id}\"\n" $pubiprg $pubipnam >> $prefix-$name.tf
                fi
                #printf "\t\t application_gateway_backend_address_pools_ids = \"%s\" \n"  $subipalloc >> $prefix-$name.tf
                #printf "\t\t load_balancer_backend_address_pools_ids = \"%s\" \n"  $subipalloc >> $prefix-$name.tf
                #printf "\t\t load_balancer_inbound_nat_rules_ids = \"%s\" \n"  $subipalloc >> $prefix-$name.tf
                #printf "\t\t application_security_group_ids = \"%s\" \n"  $subipalloc >> $prefix-$name.tf
                printf "\t\t primary = \"%s\" \n"  $prim >> $prefix-$name.tf

                printf "\t}\n" >> $prefix-$name.tf
        #

        done
        fi
        #printf "\t private_ip_address = \"%s\" \n"  $pprivip >> $prefix-$name.tf
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
