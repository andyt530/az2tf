 printf "\tssh_keys {\n"  >> $prefix-$name.tf
                printf "\t\tpath = \"%s\" \n" $vmsshpath >> $prefix-$name.tf
                echo "		key_data = \"$vmsshkey\""  >> $prefix-$name.tf
                printf "\t}\n" >> $prefix-$name.tf
            fi
            printf "}\n" >> $prefix-$name.tf
        fi
        #
        # Data disks
        #
        #echo $datadisks | jq .
        dcount=`echo $datadisks | jq '. | length'`
        dcount=$(($dcount-1))
        
        for j in `seq 0 $dcount`; do
            ddname=`echo $datadisks | jq ".[(${j})].name" | tr -d '"'`
            if [ "$ddname" != "null" ]; then
                ddcreopt=`echo $datadisks | jq ".[(${j})].createOption" | tr -d '"'`
                ddlun=`echo $datadisks | jq ".[(${j})].lun" | tr -d '"'`
                ddvhd=`echo $datadisks | jq ".[(${j})].vhd.uri" | tr -d '"'`
                printf "storage_data_disk {\n"  >> $prefix-$name.tf
                printf "\t name = \"%s\"\n" $ddname >> $prefix-$name.tf
                printf "\t create_option = \"%s\"\n" $ddcreopt >> $prefix-$name.tf
                printf "\t lun = \"%s\"\n" $ddlun >> $prefix-$name.tf
                
                if [ "$ddcreopt" = "Attach" ]; then
                    ddmdid=`echo $datadisks | jq ".[(${j})].managedDisk.id" | cut -d'/' -f9 | tr -d '"'`
                    ddmdrg=`echo $datadisks | jq ".[(${j})].managedDisk.id" | cut -d'/' -f5 | tr -d '"'`
                    ## ddmdrg  from cut is upper case - not good
                    ## probably safe to assume managed disk in same RG as VM ??
                    # check id lowercase rg = ddmdrg if so use rg
                    #
                    #if not will have to get from terraform state - convert ddmdrg to lc and terraform state output
                    #
                    
                    printf "\t managed_disk_id = \"\${azurerm_managed_disk.%s__%s.id}\"\n" $rg $ddmdid >> $prefix-$name.tf
                fi
                if [ "$ddvhd" != "null" ]; then
                    printf "\t vhd_uri = \"%s\"\n" $ddvhd >> $prefix-$name.tf
                fi
                
                printf "}\n" >> $prefix-$name.tf
            fi
        done
        
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
