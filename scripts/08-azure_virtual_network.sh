tfp="azurerm_virtual_network"
prefix="vnet"
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
azr=`az network vnet list -g $rgsource`
#
# loop around vnets
#
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
        dns1=`echo $azr | jq ".[(${i})].dhcpOptions.dnsServers[0]"`
        dns2=`echo $azr | jq ".[(${i})].dhcpOptions.dnsServers[1]"`
        echo $dns1
        echo $dns2
        dns="null"
        if [ "$dns1" != "null" ]; then
            dns=`printf "[%s]" $dns1`
        fi
        if [ "$dns2" != "null" ]; then
            dns=`printf "[%s,%s]" $dns1 $dns2`
        fi
        addsp1=`echo $azr | jq ".[(${i})].addressSpace.addressPrefixes[0]"`
        addsp2=`echo $azr | jq ".[(${i})].addressSpace.addressPrefixes[1]"`
        addsp3=`echo $azr | jq ".[(${i})].addressSpace.addressPrefixes[2]"`
        addsp4=`echo $azr | jq ".[(${i})].addressSpace.addressPrefixes[3]"`
        addsp="null"
        if [ "$addsp1" != "null" ]; then
            addsp=`printf "[%s]" $addsp1`
        fi
        if [ "$addsp2" != "null" ]; then
            addsp=`printf "[%s,%s]" $addsp1 $addsp2`
        fi
        printf "resource \"%s\" \"%s\" { \n" $tfp $name > $prefix-$name.tf
        printf "\tname = \"%s\"\n" $name >> $prefix-$name.tf
        printf "\t location = \"\${var.loctarget}\"\n" >> $prefix-$name.tf
        #printf "\t resource_group_name = \"\${var.rgtarget}\"\n"  >> $prefix-$name.tf
        printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
        printf "\t dns_servers = %s\n" $dns >> $prefix-$name.tf
        
        #
        # need to loop around prefixes
        #
        printf "\taddress_space = %s\n" $addsp >> $prefix-$name.tf
        #
        #loop around subnets
        #
        subs=`echo $azr | jq ".[(${i})].subnets"`
        count=`echo $subs | jq '. | length'`
        count=`expr $count - 1`
        for j in `seq 0 $count`; do
            snname=`echo $subs | jq ".[(${j})].name"`
            snaddr=`echo $subs | jq ".[(${j})].addressPrefix"`
            snnsgid=`echo $subs | jq ".[(${j})].networkSecurityGroup.id"`
            nsgnam=`echo $snnsgid | cut -d'/' -f9 | tr -d '"'`
            printf "\tsubnet {\n"  >> $prefix-$name.tf
            printf "\t\t name = %s\n" $snname >> $prefix-$name.tf
            printf "\t\t address_prefix = %s\n" $snaddr >> $prefix-$name.tf
            if [ "$nsgnam" != "null" ]; then
                printf "\t\t security_group = \"\${azurerm_network_security_group.%s.id}\"\n" $nsgnam >> $prefix-$name.tf
            fi
            printf "\t}\n" >> $prefix-$name.tf
            echo "}" >> $prefix-$name.tf
        done
        #
        #
        cat $prefix-$name.tf
        terraform state rm $tfp.$name
        terraform import $tfp.$name $id
    done
fi
