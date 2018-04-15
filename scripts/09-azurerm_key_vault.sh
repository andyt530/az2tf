tfp="azurerm_key_vault"
prefixa="kv"
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
azr=`az keyvault list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        kvshow=`az keyvault show -n $name`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        loc=`echo $azr | jq ".[(${i})].location" | tr -d '"'`
        
        sku=`echo $kvshow | jq ".properties.sku.name" | tr -d '"'`
        ten=`echo $kvshow | jq ".properties.tenantId" | tr -d '"'`
        #echo $tags | jq .
        ap=`echo $kvshow | jq ".properties.accessPolicies"`
        
        prefix=`printf "%s_%s" $prefixa $rg`
        
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name > $prefix-$name.tf
        printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
        printf "\t location = \"%s\"\n" $loc >> $prefix-$name.tf
        printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
        #
        printf "\t sku { \n" >> $prefix-$name.tf
        printf "\t\t name=\"%s\"\n" $sku >> $prefix-$name.tf
        printf "\t } \n" >> $prefix-$name.tf
        
        printf "\t tenant_id=\"%s\"\n" $ten >> $prefix-$name.tf
        #
        # Access Policies
        #
        pcount=`echo $ap | jq '. | length'`
        if [ "$pcount" -gt "0" ]; then
        echo $pcount
           for j in `seq 1 $pcount`; do
           echo $j
              printf "\taccess_policy {\n" >> $prefix-$name.tf
                echo $ap | jq ".properties.accessPolicies[(${j})].tenantId" | tr -d '"'
               printf "\t}\n" >> $prefix-$name.tf
           done
        fi
        
        #
        # Tags block
        #
        tags=`echo $azr | jq ".[(${i})].tags"`
        tcount=`echo $tags | jq '. | length'`
        #echo $tcount
        if [ "$tcount" -gt "0" ]; then
            printf "\t tags { \n" >> $prefix-$name.tf
            tt=`echo $tags | jq .`
            for j in `seq 1 $tcount`; do
                atag=`echo $tt | cut -d',' -f$j | tr -d '{' | tr -d '}'`
                tkey=`echo $atag | cut -d':' -f1 | tr -d '"'`
                tval=`echo $atag | cut -d':' -f2`
                printf "\t\t%s = %s \n" $tkey $tval >> $prefix-$name.tf
                
            done
            printf "\t}\n" >> $prefix-$name.tf
        fi
        
        printf "}\n" >> $prefix-$name.tf
        
        cat $prefix-$name.tf
        statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $name`
        eval $statecomm
        evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $name $id`
        eval $evalcomm
        
        
    done
fi
