tfp="azurerm_virtual_machine"
echo $tfp
prefixa="vm"
if [ "$1" != "" ]; then
    rgsource=$1
else
    echo -n "Enter name of Resource Group [$rgsource] > "
    read response
    if [ -n "$response" ]; then
        rgsource=$response
    fi
fi
azr=`az vm list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
        prefix=`printf "%s_%s" $prefixa $rg`
        #
        #
        #
        tavs=`terraform state list | grep azurerm_availability_set | cut -f2 -d'.'`
        
        avsid=`echo $azr | jq ".[(${i})].availabilitySet.id" | cut -f9 -d'/' | tr -d '"'`
        uavsid=`echo $avsid | awk '{print toupper($0)}'`
        for j in $tavs; do
            uj=`echo $j | awk '{print toupper($0)}'`
            # echo $uj  $uavsid $j
            if [ "$uavsid" = "$uj" ] ; then
                avsid=$j
            fi
        done
        echo "contunue"
        vmtype=`echo $azr | jq ".[(${i})].storageProfile.osDisk.osType" | tr -d '"'`
        vmsize=`echo $azr | jq ".[(${i})].hardwareProfile.vmSize" | tr -d '"'`
        vmdiags=`echo $azr | jq ".[(${i})].diagnosticsProfile" | tr -d '"'`
        vmbturi=`echo $azr | jq ".[(${i})].diagnosticsProfile.bootDiagnostics.storageUri" | tr -d '"'`
        netifs=`echo $azr | jq ".[(${i})].networkProfile.networkInterfaces"`
        datadisks=`echo $azr | jq ".[(${i})].storageProfile.dataDisks"`
        vmnetid=`echo $azr | jq ".[(${i})].networkProfile.networkInterfaces[0].id" | cut -d'/' -f9 | tr -d '"'`
        vmosdiskname=`echo $azr | jq ".[(${i})].storageProfile.osDisk.name" | tr -d '"'`
        vmosdiskcache=`echo $azr | jq ".[(${i})].storageProfile.osDisk.caching" | tr -d '"'`
        vmosvhd=`echo $azr | jq ".[(${i})].storageProfile.osDisk.vhd.uri" | tr -d '"'`
        vmoscreoption=`echo $azr | jq ".[(${i})].storageProfile.osDisk.createOption" | tr -d '"'`
        #
        
        osvhd=`echo $azr | jq ".[(${i})].osProfile.linuxConfiguration.ssh.publicKeys[0].keyData" | tr -d '"'`
        
        #
        vmimid=`echo $azr | jq ".[(${i})].storageProfile.imageReference.id" | tr -d '"'`

        vmimoffer=`echo $azr | jq ".[(${i})].storageProfile.imageReference.offer" | tr -d '"'`
        vmimpublisher=`echo $azr | jq ".[(${i})].storageProfile.imageReference.publisher" | tr -d '"'`
        vmimsku=`echo $azr | jq ".[(${i})].storageProfile.imageReference.sku" | tr -d '"'`
        vmimversion=`echo $azr | jq ".[(${i})].storageProfile.imageReference.version" | tr -d '"'`
        #
        vmadmin=`echo $azr | jq ".[(${i})].osProfile.adminUsername" | tr -d '"'`
        vmdispw=`echo $azr | jq ".[(${i})].osProfile.linuxConfiguration.disablePasswordAuthentication" | tr -d '"'`
        vmsshpath=`echo $azr | jq ".[(${i})].osProfile.linuxConfiguration.ssh.publicKeys[0].path" | tr -d '"'`
        vmsshkey=`echo $azr | jq ".[(${i})].osProfile.linuxConfiguration.ssh.publicKeys[0].keyData" | tr -d '"'`
        #
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name > $prefix-$name.tf
        printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
        printf "\t location = \"\${var.loctarget}\"\n"  >> $prefix-$name.tf
        #printf "\t resource_group_name = \"\${var.rgtarget}\"\n" $myrg >> $prefix-$name.tf
        printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
        if [ "$avsid" != "null" ]; then 
            printf "\t availability_set_id = \"\${azurerm_availability_set.%s.id}\"\n" $avsid >> $prefix-$name.tf
        fi
        printf "\t vm_size = \"%s\"\n" $vmsize >> $prefix-$name.tf
        printf "\t network_interface_ids = [\"\${azurerm_network_interface.%s.id}\"]\n" $vmnetid >> $prefix-$name.tf
        printf "\t delete_data_disks_on_termination = \"true\"\n"  >> $prefix-$name.tf
        printf "\t delete_os_disk_on_termination = \"true\"\n"  >> $prefix-$name.tf
        #
        printf "os_profile {\n"  >> $prefix-$name.tf
        printf "\tcomputer_name = \"%s\" \n"  $name >> $prefix-$name.tf
        printf "\tadmin_username = \"%s\" \n"  $vmadmin >> $prefix-$name.tf
        printf "}\n" >> $prefix-$name.tf
        #
        # OS Disk
        #
        echo vmosacctype $vmosacctype
        printf "storage_os_disk {\n"  >> $prefix-$name.tf
        printf "\tname = \"%s\" \n"  $vmosdiskname >> $prefix-$name.tf
        printf "\tcaching = \"%s\" \n" $vmosdiskcache  >>  $prefix-$name.tf
        if [ "$vmosacctype" != "" ]; then
            printf "\tmanaged_disk_type = \"%s\" \n" $vmosacctype >> $prefix-$name.tf
        fi
        if [ "$vmosvhd" != "null" ]; then
            printf "\tvhd_uri = \"%s\" \n" $vmosvhd >> $prefix-$name.tf
        fi
        printf "\tcreate_option = \"%s\" \n" $vmoscreoption >> $prefix-$name.tf
        printf "\tos_type = \"%s\" \n" $vmtype >> $prefix-$name.tf
        printf "}\n" >> $prefix-$name.tf
        #
        #
        #
        echo vmimid $vmimid
        if [ "$vmimid" = "null" ]; then
            printf "storage_image_reference {\n"  >> $prefix-$name.tf
            printf "\t publisher = \"%s\"\n" $vmimpublisher  >> $prefix-$name.tf
            printf "\t offer = \"%s\"\n"  $vmimoffer >> $prefix-$name.tf
            printf "\t sku = \"%s\"\n"  $vmimsku >> $prefix-$name.tf
            printf "\t version = \"%s\"\n"  $vmimversion >> $prefix-$name.tf
            printf "}\n" >> $prefix-$name.tf
        fi
        #
        #
        #
        if [ "$vmdiags" != "null" ]; then
            printf "boot_diagnostics {\n"  >> $prefix-$name.tf
            printf "\t enabled = \"true\"\n"  >> $prefix-$name.tf
            printf "\t storage_uri = \"%s\"\n" $vmbturi >> $prefix-$name.tf
            printf "}\n" >> $prefix-$name.tf
        fi
        #
        if [ $vmtype = "Windows" ]; then
            vmwau=`echo $azr | jq ".[(${i})].osProfile.windowsConfiguration.enableAutomaticUpdates" | tr -d '"'`
            vmwvma=`echo $azr | jq ".[(${i})].osProfile.windowsConfiguration.provisionVmAgent" | tr -d '"'`
            printf "os_profile_windows_config {\n"  >> $prefix-$name.tf
            printf "\t enable_automatic_upgrades = \"%s\"\n" $vmwau >> $prefix-$name.tf
            printf "\t provision_vm_agent = \"%s\"\n" $vmwvma >> $prefix-$name.tf
            printf "}\n" >> $prefix-$name.tf
        fi
        #
        if [ $vmtype = "Linux" ]; then
            printf "os_profile_linux_config {\n"  >> $prefix-$name.tf
            printf "\tdisable_password_authentication = \"%s\" \n" $vmdispw >> $prefix-$name.tf
            printf "\tssh_keys {\n"  >> $prefix-$name.tf
            printf "\t\tpath = \"%s\" \n" $vmsshpath >> $prefix-$name.tf
            echo "		key_data = \"$vmsshkey\""  >> $prefix-$name.tf
            printf "\t}\n" >> $prefix-$name.tf
            printf "}\n" >> $prefix-$name.tf
        fi
        #
        # Data disks
        #
        echo $datadisks | jq .
        dcount=`echo $datadisks | jq '. | length'`
        dcount=$(($dcount-1))
        echo dcount $dcount
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
                    printf "\t managed_disk_id = \"\${azurerm_managed_disk.%s.id}\"\n" $ddmdid >> $prefix-$name.tf
                fi
                if [ "$ddvhd" != "null" ]; then
                    printf "\t vhd_uri = \"%s\"\n" $ddvhd >> $prefix-$name.tf
                fi
                
                printf "}\n" >> $prefix-$name.tf
            fi
        done
        printf "}\n" >> $prefix-$name.tf
        cat $prefix-$name.tf
        statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $name`
        eval $statecomm
        evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $name $id`
        eval $evalcomm
    done
fi
