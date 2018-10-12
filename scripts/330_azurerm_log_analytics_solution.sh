prefixa=`echo $0 | awk -F 'azurerm_' '{print $2}' | awk -F '.sh' '{print $1}' `
tfp=`printf "azurerm_%s" $prefixa`

echo $TF_VAR_rgtarget
if [ "$1" != "" ]; then
    rgsource=$1
fi

at=`az account get-access-token`
bt=`echo $at | jq .accessToken | tr -d '"'`
sub=`echo $at | jq .subscription | tr -d '"'`


ris=`printf "curl -s  -X GET -H \"Authorization: Bearer %s\" -H \"Content-Type: application/json\" https://management.azure.com/subscriptions/%s/resourceGroups/%s/providers/Microsoft.OperationsManagement/solutions?api-version=2015-11-01-preview" $bt $sub $rgsource`
#echo $ris
ret=`eval $ris`
azr2=`echo $ret | jq .value`
rg=$rgsource
count2=`echo $azr2 | jq '. | length'`
if [ "$count2" -gt "0" ]; then
    count2=`expr $count2 - 1`
    for j in `seq 0 $count2`; do
        
        azr=`echo $azr2 | jq ".[(${j})]"`
        count=`echo $azr | jq '. | length'`
        if [ "$count" -gt "0" ]; then
            name=`echo $azr | jq ".name" | tr -d '"'`
            pname=`echo $name`
            name=`echo $name | sed s/\(/-/`
            name=`echo $name | sed s/\)/-/`
            
            
            id=`echo $azr | jq ".id" | tr -d '"'`
            skip="false"
            if [[ $id = *"["* ]]; then
            echo "Skipping this soluion $pname - can't process currently"
            skip="true"
            fi


            loc=`echo $azr | jq ".location"`
            rg=$rgsource
            pub=`echo $azr | jq ".plan.publisher"`
            prod=`echo $azr | jq ".plan.product" | tr -d '"'`
            soln=`echo $azr | jq ".plan.product" | cut -f2 -d'/' | tr -d '"'`
            workname=`echo $azr | jq ".properties.workspaceResourceId" | cut -d'/' -f9 | tr -d '"'`
            workid=`echo $azr | jq ".properties.workspaceResourceId" | tr -d '"'`
            
            prefix=`printf "%s__%s" $prefixa $rg`
            outfile=`printf "%s.%s__%s.tf" $tfp $rg $name` 
            echo $az2tfmess > $outfile
            
            if [ "$skip" != "true" ]; then
                
                printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name >> $outfile
                
                printf "\t location = %s\n" "$loc" >> $outfile
                printf "\t resource_group_name = \"%s\"\n" $rg >> $outfile
                printf "\t solution_name = \"%s\"\n" $soln >> $outfile
                printf "\t workspace_name = \"%s\"\n" $workname >> $outfile
                printf "\t workspace_resource_id = \"%s\"\n" $workid >> $outfile
                
                printf "\t plan {\n"  >> $outfile
                printf "\t\t publisher = %s\n" "$pub" >> $outfile
                printf "\t\t product = \"%s\"\n" "$prod" >> $outfile
                printf "\t } \n" >> $outfile
                
                #
                # New Tags block
                tags=`echo $azr | jq ".tags"`
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
                cat $outfile
                
                statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg '$name'`
                echo $statecomm
                echo $statecomm >> tf-staterm.sh
                eval $statecomm
                evalcomm=`printf "terraform import %s.%s__%s \"%s\"" $tfp $rg $name $id`
                echo $evalcomm
                echo $evalcomm >> tf-stateimp.sh
                eval $evalcomm
            fi
            
            #done
        fi
        
    done
fi
