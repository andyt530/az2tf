tfp="azurerm_managed_disk"
prefixa="md"
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
azr=`az disk list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"' | awk '{print tolower($0)}'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"' | awk '{print tolower($0)}'`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`

        prefix=`printf "%s_%s" $prefixa $rg`
        echo $prefix
        dsize=`echo $azr | jq ".[(${i})].diskSizeGb" | tr -d '"'`
        ostyp=`echo $azr | jq ".[(${i})].osType" | tr -d '"'`
        creopt=`echo $azr | jq ".[(${i})].creationData.createOption" | tr -d '"'`
        stopt=`echo $azr | jq ".[(${i})].sku.name" | tr -d '"'`
        imid=`echo $azr | jq ".[(${i})].creationData.imageReference.id" | tr -d '"'`
       
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name > $prefix-$name.tf
        printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
        printf "\t location = \"\${var.loctarget}\"\n" >> $prefix-$name.tf
        #printf "\t resource_group_name = \"\${var.rgtarget}\"\n" >> $prefix-$name.tf
        printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
        printf "\t disk_size_gb = \"%s\"\n" $dsize >> $prefix-$name.tf
        if [ "$ostyp" != "null" ]; then 
            printf "\t os_type = \"%s\"\n" $ostyp >> $prefix-$name.tf
        fi
        if [ "$imid" != "null" ]; then 
            printf "\t image_reference_id = \"%s\"\n" $imid >> $prefix-$name.tf
        fi
        if [ "$creopt" != "null" ]; then 
            printf "\t create_option = \"%s\"\n" $creopt >> $prefix-$name.tf
        fi
        if [ "$stopt" != "null" ]; then 
            printf "\t storage_account_type = \"%s\"\n" $stopt >> $prefix-$name.tf
        fi


        printf "}\n" >> $prefix-$name.tf
        #
        cat $prefix-$name.tf
        statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $name`
        eval $statecomm
        evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $name $id`
        eval $evalcomm
    done
fi
