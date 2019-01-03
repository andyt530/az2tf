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
azr=`az webapp list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        rname=`echo $name | sed 's/\./-/g'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup"  | tr -d '"'`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        loc=`echo $azr | jq ".[(${i})].location"`
        prg=`echo $azr | jq ".[(${i})].appServicePlanId" | cut -d'/' -f5  | tr -d '"'`
        pnam=`echo $azr | jq ".[(${i})].appServicePlanId" | cut -d'/' -f9 | tr -d '"'`
        lcrg=`echo $azr | jq ".[(${i})].resourceGroup" | awk '{print tolower($0)}' | tr -d '"'`
        appplid=`echo $azr | jq ".[(${i})].appServicePlanId" | tr -d '"'`
        rg=`echo $lcrg | sed 's/\./-/g'`

        prefix=`printf "%s.%s" $prefixa $rg`
        outfile=`printf "%s.%s__%s.tf" $tfp $rg $rname`
        echo $az2tfmess > $outfile  
        
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $rname >> $outfile
        printf "\t name = \"%s\"\n" $name >> $outfile
        printf "\t location = %s\n" "$loc" >> $outfile
        printf "\t resource_group_name = \"%s\"\n" $lcrg >> $outfile
        # case issues - so use resource id directly
        # printf "\t app_service_plan_id = \"\${azurerm_app_service_plan.%s__%s.id}\"\n" $prg $pnam >> $outfile
        printf "\t app_service_plan_id = \"%s\"\n" $appplid >> $outfile


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
        # New Tags block v2
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
                #echo "key=$k1"
                re="[[:space:]]+"
                if [[ $k1 =~ $re ]]; then
                #echo "found a space"
                tval=`echo $tt | jq ."$k1"`
                tkey=`echo $k1 | tr -d '"'`
                printf "\t\t\"%s\" = %s \n" "$tkey" "$tval" >> $outfile
                else
                #echo "found no space"
                tval=`echo $tt | jq .$k1`
                tkey=`echo $k1 | tr -d '"'`
                printf "\t\t%s = %s \n" $tkey "$tval" >> $outfile
                fi
            done
            printf "\t}\n" >> $outfile
        fi
        
        
        printf "}\n" >> $outfile
        #

        cat $outfile
        statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $rname`
        echo $statecomm >> tf-staterm.sh
        eval $statecomm
        evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $rname $id`
        echo $evalcomm >> tf-stateimp.sh
        eval $evalcomm
    done
fi
