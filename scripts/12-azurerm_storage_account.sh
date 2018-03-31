tfp="azurerm_storage_account"
prefix="stor"
echo $tfp
if [ "$1" != "" ]; then
rgsource=$1
else
echo -n "Enter name of Resource Group [$rgsource] > "
read response
if [ -n "$response" ]; then
     rgsource=$response
fi
fi
azr=`az storage account list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
count=`expr $count - 1`
for i in `seq 0 $count`; do
#echo $i
name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
satier=`echo $azr | jq ".[(${i})].sku.tier" | tr -d '"'`
sartype=`echo $azr | jq ".[(${i})].sku.name" | cut -f2 -d'_' | tr -d '"'`
saencrypt=`echo $azr | jq ".[(${i})].encryption.services.blob.enabled" | tr -d '"'`
sahttps=`echo $azr | jq ".[(${i})].enableHttpsTrafficOnly" | tr -d '"'`
printf "resource \"%s\" \"%s\" {\n" $tfp $name > $prefix-$name.tf
printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
printf "\t location = \"\${var.loctarget}\"\n" >> $prefix-$name.tf
#printf "\t resource_group_name = \"\${var.rgtarget}\"\n" >> $prefix-$name.tf
printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
printf "\t account_tier = \"%s\"\n" $satier >> $prefix-$name.tf
printf "\t account_replication_type = \"%s\"\n" $sartype >> $prefix-$name.tf
printf "\t enable_blob_encryption = \"%s\"\n" $saencrypt >> $prefix-$name.tf
printf "\t enable_https_traffic_only = \"%s\"\n" $sahttps >> $prefix-$name.tf
#
printf "}\n" >> $prefix-$name.tf
#
cat $prefix-$name.tf
terraform state rm $tfp.$name 
terraform import $tfp.$name $id
done
fi
