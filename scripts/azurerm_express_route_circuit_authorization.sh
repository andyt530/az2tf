tfp="azurerm_express_route_circuit_authorization"
prefixa="era"
echo $TF_VAR_rgtarget
if [ "$1" != "" ]; then
    rgsource=$1
fi
at=`az account get-access-token`
bt=`echo $at | jq .accessToken | tr -d '"'`
sub=`echo $at | jq .subscription | tr -d '"'`


ris=`printf "curl -s  -X GET -H \"Authorization: Bearer %s\" -H \"Content-Type: application/json\" https://management.azure.com/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Network/expressRouteCircuits?api-version=2018-01-01" $bt $sub $rgsource`
# count how many of this provider type there are.
ret=`eval $ris`
azr2=`echo $ret | jq .value`
rg=$rgsource
count2=`echo $azr2 | jq '. | length'`
if [ "$count2" -gt "0" ]; then
    count2=`expr $count2 - 1`
    for j in `seq 0 $count2`; do
        
        name2=`echo $azr2 | jq ".[(${j})].name" | tr -d '"'`
        ris2=`printf "curl -s -X GET -H \"Authorization: Bearer %s\" -H \"Content-Type: application/json\" https://management.azure.com/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Network/expressRouteCircuits/%s?api-version=2018-01-01" $bt $sub $rgsource $name2`
        #echo $ris2
        ret2=`eval $ris2`
        azr=`echo $ret2 | jq .`
        #echo $ret2 | jq .
        count=`echo $azr | jq '. | length'`
        if [ "$count" -gt "0" ]; then
            
            
            auths=`echo $azr | jq ".properties.authorizations"`
            echo $auths | jq .
            
            acount=`echo $auths | jq '. | length'`
            if [ "$acount" -gt "0" ]; then
                acount=`expr $acount - 1`
                for k in `seq 0 $acount`; do
                

                name=`echo $auths | jq ".[(${k})].name" | tr -d '"'`
                id=`echo $auths | jq ".[(${k})].id" | tr -d '"'`
                
                rg=$rgsource
                prefix=`printf "%s__%s" $prefixa $rg`
                echo $az2tfmess > $prefix-$name.tf
                
                printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name >> $prefix-$name.tf
                printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
                printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
                printf "\t express_route_circuit_name = \"%s\"\n" $name2 >> $prefix-$name.tf
                
                
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
                
                done
                
            fi
            
            #done
        fi
        
    done
fi
