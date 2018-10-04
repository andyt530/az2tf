tfp="azurerm_log_analytics_workspace"
prefixa="law"
echo $TF_VAR_rgtarget
if [ "$1" != "" ]; then
    rgsource=$1
fi
at=`az account get-access-token`
bt=`echo $at | jq .accessToken | tr -d '"'`
sub=`echo $at | jq .subscription | tr -d '"'`


ris=`printf "curl -s  -X GET -H \"Authorization: Bearer %s\" -H \"Content-Type: application/json\" https://management.azure.com/subscriptions/%s/resourceGroups/%s/providers/Microsoft.OperationalInsights/workspaces?api-version=2015-11-01-preview" $bt $sub $rgsource`
#echo $ris
ret=`eval $ris`
azr2=`echo $ret | jq .value`
rg=$rgsource
count2=`echo $azr2 | jq '. | length'`
if [ "$count2" -gt "0" ]; then
    count2=`expr $count2 - 1`
    for j in `seq 0 $count2`; do
           
        name2=`echo $azr2 | jq ".[(${j})].name" | tr -d '"'`
        ris2=`printf "curl -s -X GET -H \"Authorization: Bearer %s\" -H \"Content-Type: application/json\" https://management.azure.com/subscriptions/%s/resourceGroups/%s/providers/Microsoft.OperationalInsights/workspaces/%s?api-version=2015-11-01-preview" $bt $sub $rgsource $name2`
        #echo $ris2
        ret2=`eval $ris2`
        azr=`echo $ret2 | jq .`
        #echo $ret2 | jq .
        count=`echo $azr | jq '. | length'`
        if [ "$count" -gt "0" ]; then
                name=`echo $azr | jq ".name" | tr -d '"'`
                id=`echo $azr | jq ".id" | tr -d '"'`
                loc=`echo $azr | jq ".location"`
                rg=$rgsource
                sku=`echo $azr | jq ".properties.sku.name"`
                rdays=`echo $azr | jq ".properties.retentionInDays"`
                prefix=`printf "%s__%s" $prefixa $rg`
                
                printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name > $prefix-$name.tf
                printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
                printf "\t location = %s\n" "$loc" >> $prefix-$name.tf
                printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf            
                printf "\t sku = %s \n" "$sku" >> $prefix-$name.tf
                # 7 is not a valid value, but is the default reported from AZ api. If 7, skip to avoid triggering plan difference
                if [ "$rdays" -ne "7" ]; then
                    printf "\t retention_in_days = %s \n" "$rdays" >> $prefix-$name.tf
                fi
                
                #
                # New Tags block
                tags=`echo $azr | jq ".tags"`
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
                cat $prefix-$name.tf
                statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $name`
                echo $statecomm >> tf-staterm.sh
                eval $statecomm
                evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $name $id`
                echo $evalcomm >> tf-stateimp.sh
                eval $evalcomm               
 
            #done
        fi      
        
    done
fi
