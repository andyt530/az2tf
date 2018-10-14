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
azr=`az appservice plan list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`

        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        loc=`echo $azr | jq ".[(${i})].location"`
        tier=`echo $azr | jq ".[(${i})].sku.tier" | tr -d '"'`
        size=`echo $azr | jq ".[(${i})].sku.size" | tr -d '"'`
        kind=`echo $azr | jq ".[(${i})].kind" | tr -d '"'`
        lcrg=`echo $azr | jq ".[(${i})].resourceGroup" | awk '{print tolower($0)}' | tr -d '"'`

        #if [ "$kind" = "app" ];then kind="Windows"; fi
        prefix=`printf "%s.%s" $prefixa $rg`
        outfile=`printf "%s.%s__%s.tf" $tfp $rg $name`
        echo $az2tfmess > $outfile  
        
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name >> $outfile
        printf "\t name = \"%s\"\n" $name >> $outfile
        printf "\t location = %s\n" "$loc" >> $outfile
        printf "\t resource_group_name = \"%s\"\n" $lcrg >> $outfile
        printf "\t kind = \"%s\"\n" $kind >> $outfile

        printf "\t sku {\n" >> $outfile
        printf "\t\t tier = \"%s\"\n" $tier >> $outfile
        printf "\t\t size = \"%s\"\n" $size >> $outfile
        printf "\t }\n" >> $outfile

        
# geo location block
        
#        icount=`echo $geol | jq '. | length'`
#        if [ "$icount" -gt "0" ]; then
#            icount=`expr $icount - 1`
#            for j in `seq 0 $icount`; do
#                floc=`echo $azr | jq ".[(${i})].failoverPolicies[(${j})].locationName"`
#                fop=`echo $azr | jq ".[(${i})].failoverPolicies[(${j})].failoverPriority" | tr -d '"'`
#                printf "\t geo_location { \n"  >> $outfile
#                printf "\t location = %s \n"  "$floc" >> $outfile
#                printf "\t failover_priority  = \"%s\" \n"  $fop >> $outfile
#                printf "}\n" >> $outfile
#            done
#        fi

        
        #
        # New Tags block
        tags=`echo $azr | jq ".[(${i})].tags"`
        tt=`echo $tags | jq .`
        tcount=`echo $tags | jq '. | length'`
        if [ "$tcount" -gt "0" ]; then
            printf "\t tags { \n" >> $outfile
            tt=`echo $tags | jq .`
            keys=`echo $tags | jq 'keys'`
            tcount=`expr $tcount - 1`
            for j in `seq 0 $tcount`; do
                k1=`echo $keys | jq ".[(${j})]"`
                tval=`echo $tt | jq .$k1`
                tkey=`echo $k1 | tr -d '"'`
                printf "\t\t%s = %s \n" $tkey "$tval" >> $outfile
            done
            printf "\t}\n" >> $outfile
        fi
        
        
        printf "}\n" >> $outfile
        #
        echo $prefix
        echo $prefix__$name
        cat $outfile
        statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $name`
        echo $statecomm >> tf-staterm.sh
        eval $statecomm
        evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $name $id`
        echo $evalcomm >> tf-stateimp.sh
        eval $evalcomm
    done
fi
