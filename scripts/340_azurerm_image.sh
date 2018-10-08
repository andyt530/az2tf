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
azr=`az image list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" != "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        loc=`echo $azr | jq ".[(${i})].location" | tr -d '"'`
        osdisk=`echo $azr | jq ".[(${i})].storageProfile.osDisk" | tr -d '"'`
        ostype=`echo $azr | jq ".[(${i})].storageProfile.osDisk.osType" | tr -d '"'`
        osstate=`echo $azr | jq ".[(${i})].storageProfile.osDisk.osState" | tr -d '"'`
        oscache=`echo $azr | jq ".[(${i})].storageProfile.osDisk.caching" | tr -d '"'`
        blob_uri=`echo $azr | jq ".[(${i})].storageProfile.osDisk.blobUri" | tr -d '"'`
        prefix=`printf "%s__%s" $prefixa $rg`
        
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name > $prefix-$name.tf
        printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
        printf "\t location = \"%s\"\n" $loc >> $prefix-$name.tf
        printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
        
        if [ "$odisk" != "null" ]; then
            printf "\t os_disk { \n" >> $prefix-$name.tf
            printf "\t os_type = \"%s\"\n" $ostype >> $prefix-$name.tf
            printf "\t os_state = \"%s\"\n" $osstate >> $prefix-$name.tf
            printf "\t caching = \"%s\"\n" $oscache >> $prefix-$name.tf
            if [ "$blob_uri" != "null" ]; then
                printf "\t blob_uri = \"%s\"\n" $blob_uri >> $prefix-$name.tf
            fi
            printf "\t}\n" >> $prefix-$name.tf
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
        
        #
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
