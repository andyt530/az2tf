tfp="azurerm_network_interface"
prefix="nic"
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
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
        snsg=`echo $azr | jq ".[(${i})].networkSecurityGroup.id" | cut -d'/' -f9 | tr -d '"'`
        #
        #
        #
        subname=`echo $azr | jq ".[(${i})].ipConfigurations[0].subnet.id" | cut -d'/' -f11 | tr -d '"'`
        subipid=`echo $azr | jq ".[(${i})].ipConfigurations[0].publicIpAddress.id" | cut -d'/' -f9 | tr -d '"'`
        subipalloc=`echo $azr | jq ".[(${i})].ipConfigurations[0].privateIpAllocationMethod" | tr -d '"'`
        
        printf "resource \"azurerm_network_interface\" \"%s\" {\n" $name > $prefix-$name.tf
        printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
        printf "\t location = \"\${var.loctarget}\"\n" >> $prefix-$name.tf
        #printf "\t resource_group_name = \"\${var.rgtarget}\"\n" >> $prefix-$name.tf
        printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
        if [ "$snsg" != "null" ]; then
            printf "\t network_security_group_id = \"\${azurerm_network_security_group.%s.id}\" \n"  $snsg >> $prefix-$name.tf
        fi
        printf "\t ip_configuration {\n" >> $prefix-$name.tf
        printf "\t\t name = \"%s\" \n"  "ipconfig1" >> $prefix-$name.tf
        printf "\t\t subnet_id = \"\${azurerm_subnet.%s.id}\" \n"  $subname >> $prefix-$name.tf
        printf "\t\t private_ip_address_allocation = \"%s\" \n"  $subipalloc >> $prefix-$name.tf
        if [ "$subipid" != "null" ]; then
            echo "pub ip "
            echo $subipid
            printf "\t\t public_ip_address_id = \"\${azurerm_public_ip.%s.id}\" \n"  $subipid >> $prefix-$name.tf
        fi
        printf "\t}\n" >> $prefix-$name.tf
        #
        printf "}\n" >> $prefix-$name.tf
        #
        cat $prefix-$name.tf
        terraform state rm $tfp.$name
        terraform import $tfp.$name $id
    done
fi
