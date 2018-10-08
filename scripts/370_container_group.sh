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
azr=`az container list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" != "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        loc=`echo $azr | jq ".[(${i})].location" | tr -d '"'`
        iptype=`echo $azr | jq ".[(${i})].ipAddress.type" | tr -d '"'`
        ostyp=`echo $azr | jq ".[(${i})].osType" | tr -d '"'`
        rp=`echo $azr | jq ".[(${i})].restartPolicy" | tr -d '"'`
        dnsl=`echo $azr | jq ".[(${i})].ipAddress.dnsNameLabel" | tr -d '"'`
        fqdn=`echo $azr | jq ".[(${i})].ipAddress.fqdn" | tr -d '"'`
        cont=`echo $azr | jq ".[(${i})].containers"`
        vols=`echo $azr | jq ".[(${i})].volumes"`
        irc=`echo $azr | jq ".[(${i})].imageRegistryCredentials"`
        
        
        prefix=`printf "%s__%s" $prefixa $rg`
        echo $az2tfmess > $prefix-$name.tf
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name > $prefix-$name.tf
        printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
        printf "\t location = \"%s\"\n" $loc >> $prefix-$name.tf
        printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
        printf "\t ip_address_type = \"%s\"\n" $iptype >> $prefix-$name.tf
        printf "\t os_type = \"%s\"\n" $ostyp >> $prefix-$name.tf
        printf "\t restart_policy = \"%s\"\n" $rp >> $prefix-$name.tf
        if [ "$dnsl" != "null" ]; then
            printf "\t dns_name_label = \"%s\"\n" $dnsl >> $prefix-$name.tf
        fi
        
        
        icount=`echo $cont | jq '. | length'`
        if [ "$icount" -gt "0" ]; then
            icount=`expr $icount - 1`
            for j in `seq 0 $icount`; do
                cname=`echo $azr | jq ".[(${i})].containers[(${j})].name"`
                cimg=`echo $azr | jq ".[(${i})].containers[(${j})].image"`
                ccpu=`echo $azr | jq ".[(${i})].containers[(${j})].resources.requests.cpu"`
                cmem=`echo $azr | jq ".[(${i})].containers[(${j})].resources.requests.memoryInGb"`
                cvols=`echo $azr | jq ".[(${i})].containers[(${j})].volumeMounts"`
                cport=`echo $azr | jq ".[(${i})].containers[(${j})].ports[0].port"`
                
                cport=`echo $azr | jq ".[(${i})].containers[(${j})].ports[0].port"`
                cproto=`echo $azr | jq ".[(${i})].containers[(${j})].ports[0].protocol"`
                cproto=`echo $cproto | awk '{print tolower($0)}'`
                
                vshr=`echo $azr | jq ".[(${i})].volumes[0].azureFile.shareName"`
                vsacc=`echo $azr | jq ".[(${i})].volumes[0].azureFile.storageAccountName"`
                vskey=`echo $azr | jq ".[(${i})].volumes[0].azureFile.storageAccountKey"`
                vmpath=`echo $azr | jq ".[(${i})].containers[(${j})].volumeMounts[0].mountPath"`
                vmname=`echo $azr | jq ".[(${i})].containers[(${j})].volumeMounts[0].name"`
                vmro=`echo $azr | jq ".[(${i})].containers[(${j})].volumeMounts[0].readOnly"`
                
                envs=`echo $azr | jq ".[(${i})].containers[(${j})].environmentVariables"`
                
                printf "\t container {\n" >> $prefix-$name.tf
                printf "\t\t name = %s\n" $cname >> $prefix-$name.tf
                printf "\t\t image = %s\n" $cimg >> $prefix-$name.tf
                printf "\t\t cpu = \"%s\"\n" $ccpu >> $prefix-$name.tf
                printf "\t\t memory = \"%s\"\n" $cmem >> $prefix-$name.tf
                # should be looped
                
                printf "\t\t port = \"%s\"\n" $cport >> $prefix-$name.tf
                if [ "$cproto" != "null" ]; then
                    printf "\t\t protocol = %s\n" $cproto >> $prefix-$name.tf
                fi

                if [ "$cvols" != "null" ]; then
                    printf "\t\t volume {\n" >> $prefix-$name.tf
                    printf "\t\t\t  name = %s\n" $vmname >> $prefix-$name.tf
                    printf "\t\t\t  mount_path = %s\n" $vmpath >> $prefix-$name.tf
                    printf "\t\t\t  read_only = \"%s\"\n" $vmro >> $prefix-$name.tf
                    printf "\t\t\t  share_name = %s\n" $vshr >> $prefix-$name.tf
                    printf "\t\t\t  storage_account_name = %s\n" $vsacc >> $prefix-$name.tf
                    if [ "$vskey" == "null" ]; then
                        printf "\t\t\t  storage_account_key = \"%s\"\n" >> $prefix-$name.tf
                    else
                        printf "\t\t\t  storage_account_key = \"%s\"\n" $vskey >> $prefix-$name.tf
                    fi
                    printf "\t\t }\n" >> $prefix-$name.tf
                fi
                
                kcount=`echo $envs | jq '. | length'`
                if [ "$kcount" -gt "0" ]; then
                    printf "\t\t environment_variables {\n" >> $prefix-$name.tf
                    kcount=`expr $kcount - 1`
                    for k in `seq 0 $kcount`; do
                        envn=`echo $azr | jq ".[(${i})].containers[(${j})].environmentVariables[(${k})].name"`
                        envv=`echo $azr | jq ".[(${i})].containers[(${j})].environmentVariables[(${k})].value"`
                        envs=`echo $azr | jq ".[(${i})].containers[(${j})].environmentVariables[(${k})].secureValue"`
                        printf "\t\t\t  %s = %s\n" $envn $envv >> $prefix-$name.tf
                    done
                    printf "\t\t }\n" >> $prefix-$name.tf
                fi
                             
                printf "\t }\n" >> $prefix-$name.tf
            done
        fi
        
        if [ ]; then  # comment - skip this block
        if [ "$irc" != "null" ]; then
            
            isrv=`echo $azr | jq ".[(${i})].imageRegistryCredentials[0].server"`
            iun=`echo $azr | jq ".[(${i})].imageRegistryCredentials[0].username"`
            ipw=`echo $azr | jq ".[(${i})].imageRegistryCredentials[0].password"`
            printf "\t image_registry_credential {\n" >> $prefix-$name.tf
            printf "\t\t server = %s\n" $isrv >> $prefix-$name.tf 
            printf "\t\t username = %s\n" $iun >> $prefix-$name.tf  
            # pw is problematic
            #if [ "$ipw" == "null" ]; then
            #printf "\t\t password = \"<Replace Me>\"\n"  >> $prefix-$name.tf
            #else
            #printf "\t\t password = \"%s\"\n" $ipw >> $prefix-$name.tf
            #fi
            printf "\t }\n" >> $prefix-$name.tf
        fi
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
