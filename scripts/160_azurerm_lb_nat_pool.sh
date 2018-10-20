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
azr=`az network lb list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        beap=`echo $azr | jq ".[(${i})].inboundNatPools"`
               
        icount=`echo $beap | jq '. | length'`
        if [ "$icount" -gt "0" ]; then
            icount=`expr $icount - 1`
            for j in `seq 0 $icount`; do
                
                name=`echo $azr | jq ".[(${i})].inboundNatPools[(${j})].name" | cut -d'/' -f11 | tr -d '"'`
                id=`echo $azr | jq ".[(${i})].inboundNatPools[(${j})].id" | tr -d '"'`
                rg=`echo $azr | jq ".[(${i})].inboundNatPools[(${j})].resourceGroup" | tr -d '"'`
                proto=`echo $azr | jq ".[(${i})].inboundNatPools[(${j})].protocol" | tr -d '"'`

                feipc=`echo $azr | jq ".[(${i})].inboundNatPools[(${j})].frontendIpConfiguration.id" | cut -d'/' -f11 | tr -d '"'`
                feps=`echo $azr | jq ".[(${i})].inboundNatPools[(${j})].frontendPortStart" | tr -d '"'`
                fepe=`echo $azr | jq ".[(${i})].inboundNatPools[(${j})].frontendPortEnd" | tr -d '"'`
                bep=`echo $azr | jq ".[(${i})].inboundNatPools[(${j})].backendPort" | tr -d '"'`
                prefix=`printf "%s__%s" $prefixa $rg`   
                outfile=`printf "%s.%s__%s.tf" $tfp $rg $name` 
                echo $az2tfmess > $outfile
                
                lbrg=`echo $azr | jq ".[(${i})].id" | cut -d'/' -f5 | tr -d '"'`
                lbname=`echo $azr | jq ".[(${i})].id" | cut -d'/' -f9 | tr -d '"'`
                
                printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name >> $outfile
                printf "\t\t name = \"%s\" \n"  $name >> $outfile
                printf "\t\t resource_group_name = \"%s\" \n"  $rg >> $outfile
                printf "\t\t loadbalancer_id = \"\${azurerm_lb.%s__%s.id}\"\n" $lbrg $lbname >> $outfile
                printf "\t\t protocol = \"%s\" \n"  $proto >> $outfile
                if [ "$feps" != "null" ]; then printf "\t\t frontend_port_start = \"%s\" \n"  $feps >> $outfile ; fi
                if [ "$fepe" != "null" ]; then printf "\t\t frontend_port_end = \"%s\" \n"  $fepe >> $outfile  ; fi
                printf "\t\t backend_port = \"%s\" \n"  $bep >> $outfile
                printf "\t\t frontend_ip_configuration_name = \"%s\" \n"  $feipc >> $outfile

                printf "}\n" >> $outfile
        #
                cat $outfile
                statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $name`
                echo $statecomm >> tf-staterm.sh
                eval $statecomm
                evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $name $id`
                echo $evalcomm >> tf-stateimp.sh
                eval $evalcomm




        #

        done
        fi

        


 
    done
fi
