tfp="azurerm_availability_set"
prefixa="avs"
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
azr=`az vm availability-set list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        #name=`echo $name | awk '{print tolower($0)}'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
        prefix=`printf "%s_%s" $prefixa $rg`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        fd=`echo $azr | jq ".[(${i})].platformFaultDomainCount" | tr -d '"'`
        ud=`echo $azr | jq ".[(${i})].platformUpdateDomainCount" | tr -d '"'`
        avm=`echo $azr | jq ".[(${i})].virtualMachines"`
        skuname=`echo $azr | jq ".[(${i})].sku.name" | tr -d '"'`
        rmtype="false"
        if [ $skuname = "Aligned" ]; then
            #echo "skuname is true"
            rmtype="true"
        fi
        
        #echo $avm
        #ism="true"
        #if [ "$vmcount" -eq "0" ]; then
        ##vmcount=`echo $avm | jq '. | length'`
        #    echo "vmcount is false"
        #    #ism="false"
        #fi
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name > $prefix-$name.tf
        printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
        #printf "\t id = \"%s\"\n" $id >> $prefix-$name.tf
        printf "\t location = \"\${var.loctarget}\"\n" >> $prefix-$name.tf
        #printf "\t resource_group_name = \"\${var.rgtarget}\"\n" >> $prefix-$name.tf
        printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
        printf "\t platform_fault_domain_count = \"%s\"\n" $fd >> $prefix-$name.tf
        printf "\t platform_update_domain_count = \"%s\"\n" $ud >> $prefix-$name.tf
        printf "\t managed = \"%s\"\n" $rmtype >> $prefix-$name.tf
        printf "}\n" >> $prefix-$name.tf
        #



        
        cat $prefix-$name.tf
        statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $name`
        eval $statecomm
        evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $name $id`
        eval $evalcomm
    done
fi
