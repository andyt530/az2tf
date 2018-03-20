tfp="azurerm_virtual_machine"
echo $tfp
prefix="vm"
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
count=`expr $count - 1`
for i in `seq 0 $count`; do
echo $i
name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
vmtype=`echo $azr | jq ".[(${i})].storageProfile.osDisk.osType" | tr -d '"'`
vmsize=`echo $azr | jq ".[(${i})].hardwareProfile.vmSize" | tr -d '"'`
vmbturi=`echo $azr | jq ".[(${i})].diagnosticsProfile.bootDiagnostics.storageUri" | tr -d '"'`
vmnetid=`echo $azr | jq ".[(${i})].networkProfile.networkInterfaces[0].id" | tr -d '"'`
vmosdiskname=`echo $azr | jq ".[(${i})].storageProfile.osDisk.name" | tr -d '"'`
vmosdiskcache=`echo $azr | jq ".[(${i})].storageProfile.osDisk.caching" | tr -d '"'`
vmosacctype=`echo $azr | jq ".[(${i})].storageProfile.osDisk.managedDisk.storageAccountType" | tr -d '"'`
echo $vmosacctype
vmoscreoption=`echo $azr | jq ".[(${i})].storageProfile.osDisk.createOption" | tr -d '"'`
vmadmin=`echo $azr | jq ".[(${i})].osProfile.adminUsername" | tr -d '"'`
vmdispw=`echo $azr | jq ".[(${i})].osProfile.linuxConfiguration.disablePasswordAuthentication" | tr -d '"'`
vmsshpath=`echo $azr | jq ".[(${i})].osProfile.linuxConfiguration.ssh.publicKeys[0].path" | tr -d '"'`
vmsshkey=`echo $azr | jq ".[(${i})].osProfile.linuxConfiguration.ssh.publicKeys[0].keyData" | tr -d '"'`
printf "resource \"%s\" \"%s\" {\n" $tfp $name > $prefix-$name.tf
printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
printf "\t location = \"\${var.loctarget}\"\n"  >> $prefix-$name.tf
printf "\t resource_group_name = \"\${var.rgtarget}\"\n" $myrg >> $prefix-$name.tf
printf "\t vm_size = \"%s\"\n" $vmsize >> $prefix-$name.tf
printf "\t network_interface_ids = [\"%s\"]\n" $vmnetid >> $prefix-$name.tf
printf "\t delete_data_disks_on_termination = \"true\"\n"  >> $prefix-$name.tf
printf "\t delete_os_disk_on_termination = \"true\"\n"  >> $prefix-$name.tf
#
printf "os_profile {\n"  >> $prefix-$name.tf
printf "\tcomputer_name = \"%s\" \n"  $name >> $prefix-$name.tf
printf "\tadmin_username = \"%s\" \n"  $vmadmin >> $prefix-$name.tf
printf "}\n" >> $prefix-$name.tf
#
printf "storage_os_disk {\n"  >> $prefix-$name.tf
printf "\tname = \"%s\" \n"  $vmosdiskname >> $prefix-$name.tf
printf "\tcaching = \"%s\" \n" $vmosdiskcache  >>  $prefix-$name.tf
if [ "$vmosacctype" != "null" ]; then
printf "\tmanaged_disk_type = \"%s\" \n" $vmosacctype >> $prefix-$name.tf
fi
printf "\tcreate_option = \"%s\" \n" $vmoscreoption >> $prefix-$name.tf
printf "\tos_type = \"%s\" \n" $vmtype >> $prefix-$name.tf
printf "}\n" >> $prefix-$name.tf
#
printf "boot_diagnostics {\n"  >> $prefix-$name.tf
printf "\t enabled = \"true\"\n"  >> $prefix-$name.tf
printf "\t storage_uri = \"%s\"\n" $vmbturi >> $prefix-$name.tf
printf "}\n" >> $prefix-$name.tf
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
printf "}\n" >> $prefix-$name.tf
cat $prefix-$name.tf
terraform state rm $tfp.$name 
terraform import $tfp.$name $id
done
