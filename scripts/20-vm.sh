echo "azurerm_virtual_machine"
myrg="vm-"
if [ "$1" != "" ]; then
rgsource=$1
else
echo -n "Enter name of Resource Group [$rgsource] > "
read response
if [ -n "$response" ]; then
     rgsource=$response
fi
fi
vms=`az vm list -g $rgsource`
count=`echo $vms | jq '. | length'`
count=`expr $count - 1`
for i in `seq 0 $count`; do
#echo $i
comm="echo"' $vms'" | jq '.[$i].name'"
vmname=`eval $comm | tr -d '"'`
comm="echo"' $vms'" | jq '.[$i].storageProfile.osDisk.osType'"
vmtype=`eval $comm | tr -d '"'`
comm="echo"' $vms'" | jq '.[$i].location'"
vmloc=`eval $comm | tr -d '"'`
comm="echo"' $vms'" | jq '.[$i].hardwareProfile.vmSize'"
vmsize=`eval $comm | tr -d '"'`
comm="echo"' $vms'" | jq '.[$i].diagnosticsProfile.bootDiagnostics.storageUri'"
vmbturi=`eval $comm | tr -d '"'`
comm="echo"' $vms'" | jq '.[$i].networkProfile.networkInterfaces[0].id'"
vmnetid=`eval $comm | tr -d '"'`
comm="echo"' $vms'" | jq '.[$i].storageProfile.osDisk.name'"
vmosdiskname=`eval $comm | tr -d '"'`
comm="echo"' $vms'" | jq '.[$i].storageProfile.osDisk.caching'"
vmosdiskcache=`eval $comm | tr -d '"'`
comm="echo"' $vms'" | jq '.[$i].storageProfile.osDisk.managedDisk.storageAccountType'"
vmosacctype=`eval $comm | tr -d '"'`
comm="echo"' $vms'" | jq '.[$i].storageProfile.osDisk.createOption'"
vmoscreoption=`eval $comm | tr -d '"'`
comm="echo"' $vms'" | jq '.[$i].osProfile.adminUsername'"
vmadmin=`eval $comm | tr -d '"'`
comm="echo"' $vms'" | jq '.[$i].osProfile.linuxConfiguration.disablePasswordAuthentication'"
vmdispw=`eval $comm | tr -d '"'`
comm="echo"' $vms'" | jq '.[$i].osProfile.linuxConfiguration.ssh.publicKeys[0].path'"
vmsshpath=`eval $comm | tr -d '"'`
comm="echo"' $vms'" | jq '.[$i].osProfile.linuxConfiguration.ssh.publicKeys[0].keyData'"
vmsshkey=`eval $comm | tr -d '"'`
printf "resource \"azurerm_virtual_machine\" \"%s\" {\n" $vmname > $myrg-$vmname.tf
printf "\t name = \"%s\"\n" $vmname >> $myrg-$vmname.tf
printf "\t location = \"\${var.loctarget}\"\n"  >> $myrg-$vmname.tf
printf "\t resource_group_name = \"\${var.rgtarget}\"\n" $myrg >> $myrg-$vmname.tf
printf "\t vm_size = \"%s\"\n" $vmsize >> $myrg-$vmname.tf
printf "\t network_interface_ids = [\"%s\"]\n" $vmnetid >> $myrg-$vmname.tf
printf "\t delete_data_disks_on_termination = \"true\"\n"  >> $myrg-$vmname.tf
printf "\t delete_os_disk_on_termination = \"true\"\n"  >> $myrg-$vmname.tf
#
printf "os_profile {\n"  >> $myrg-$vmname.tf
printf "\tcomputer_name = \"%s\" \n"  $vmname >> $myrg-$vmname.tf
printf "\tadmin_username = \"%s\" \n"  $vmadmin >> $myrg-$vmname.tf
printf "}\n" >> $myrg-$vmname.tf
#
printf "storage_os_disk {\n"  >> $myrg-$vmname.tf
printf "\tname = \"%s\" \n"  $vmosdiskname >> $myrg-$vmname.tf
printf "\tcaching = \"%s\" \n" $vmosdiskcache  >>  $myrg-$vmname.tf
printf "\tmanaged_disk_type = \"%s\" \n" $vmosacctype >> $myrg-$vmname.tf
printf "\tcreate_option = \"%s\" \n" $vmoscreoption >> $myrg-$vmname.tf
printf "\tos_type = \"%s\" \n" $vmtype >> $myrg-$vmname.tf
printf "}\n" >> $myrg-$vmname.tf
#
printf "boot_diagnostics {\n"  >> $myrg-$vmname.tf
printf "\t enabled = \"true\"\n"  >> $myrg-$vmname.tf
printf "\t storage_uri = \"%s\"\n" $vmbturi >> $myrg-$vmname.tf
printf "}\n" >> $myrg-$vmname.tf
#
if [ $vmtype = "Windows" ]; then
comm="echo"' $vms'" | jq '.[$i].osProfile.windowsConfiguration.enableAutomaticUpdates'"
vmwau=`eval $comm | tr -d '"'`
comm="echo"' $vms'" | jq '.[$i].osProfile.windowsConfiguration.provisionVmAgent'"
vmwvma=`eval $comm | tr -d '"'`
printf "os_profile_windows_config {\n"  >> $myrg-$vmname.tf
printf "\t enable_automatic_upgrades = \"%s\"\n" $vmwau >> $myrg-$vmname.tf
printf "\t provision_vm_agent = \"%s\"\n" $vmwvma >> $myrg-$vmname.tf
printf "}\n" >> $myrg-$vmname.tf
fi
if [ $vmtype = "Linux" ]; then
echo "Is linux"
printf "os_profile_linux_config {\n"  >> $myrg-$vmname.tf
printf "\tdisable_password_authentication = \"%s\" \n" $vmdispw >> $myrg-$vmname.tf
printf "\tssh_keys {\n"  >> $myrg-$vmname.tf
printf "\t\tpath = \"%s\" \n" $vmsshpath >> $myrg-$vmname.tf
echo "		key_data = \"$vmsshkey\""  >> $myrg-$vmname.tf
printf "\t}\n" >> $myrg-$vmname.tf
printf "}\n" >> $myrg-$vmname.tf
fi
printf "}\n" >> $myrg-$vmname.tf
#cat $myrg-$vmname.tf
done
#
for i in `seq 0 $count`; do
#echo $i
comm="echo"' $vms'" | jq '.[$i].id'"
vmid=`eval $comm | tr -d '"'`
comm="echo"' $vms'" | jq '.[$i].name'"
vmname=`eval $comm | tr -d '"'`
#echo $vmid
terraform state rm azurerm_virtual_machine.$vmname 
terraform import azurerm_virtual_machine.$vmname $vmid
done
