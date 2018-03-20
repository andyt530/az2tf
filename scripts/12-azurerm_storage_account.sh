tfp="azurerm_storage_account""
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
sal=`az storage account list -g $rgsource`
count=`echo $sal | jq '. | length'`
count=`expr $count - 1`
for i in `seq 0 $count`; do
#echo $i
saname=`echo $sal | jq '.[(${i})].name' | tr -d '"'`
satier=`echo $sal | jq '.[(${i})].sku.tier' | tr -d '"'`
sartype=`echo $sal | jq '.[(${i})].sku.name' | cut -f2 -d'_' | tr -d '"'`
saencrypt=`echo $sal | jq '.[(${i})].encryption.services.blob.enabled'  | tr -d '"'`
sahttps=`echo $sal | jq '.[(${i})].enableHttpsTrafficOnly'  | tr -d '"'`
printf "resource \"%s\" \"%s\" {\n" $tfp $saname > stor-$saname.tf
printf "\t name = \"%s\"\n" $saname >> stor-$saname.tf
printf "\t location = \"\${var.loctarget}\"\n" >> stor-$saname.tf
printf "\t resource_group_name = \"\${var.rgtarget}\"\n" >> stor-$saname.tf
printf "\t account_tier = \"%s\"\n" $satier >> stor-$saname.tf
printf "\t account_replication_type = \"%s\"\n" $sartype >> stor-$saname.tf
printf "\t enable_blob_encryption = \"%s\"\n" $saencrypt >> stor-$saname.tf
printf "\t enable_https_traffic_only = \"%s\"\n" $sahttps >> stor-$saname.tf
#
printf "}\n" >> stor-$saname.tf
#
#cat stor-$saname.tf
done
for i in `seq 0 $count`; do
saname=`echo $sal | jq '.[(${i})].name' | tr -d '"'`
said=`echo $sal | jq '.[(${i})].id' | tr -d '"'`
terraform state rm $tfp.$saname 
terraform import $tfp.$saname $said
done
