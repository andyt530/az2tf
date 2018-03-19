myrg="stor"
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
comm="echo"' $sal'" | jq '.[$i].name'"
saname=`eval $comm | tr -d '"'`
comm="echo"' $sal'" | jq '.[$i].location'"
saloc=`eval $comm | tr -d '"'`
comm="echo"' $sal'" | jq '.[$i].sku.tier'"
satier=`eval $comm | tr -d '"'`
comm="echo"' $sal'" | jq '.[$i].sku.name' | cut -f2 -d'_'"
sartype=`eval $comm | tr -d '"'`
comm="echo"' $sal'" | jq '.[$i].encryption.services.blob.enabled'"
saencrypt=`eval $comm | tr -d '"'`
comm="echo"' $sal'" | jq '.[$i].enableHttpsTrafficOnly'"
sahttps=`eval $comm | tr -d '"'`
echo $saname
printf "resource \"azurerm_storage_account\" \"%s\" {\n" $saname > $myrg-$saname.tf
printf "\t name = \"%s\"\n" $saname >> $myrg-$saname.tf
printf "\t location = \"\${var.loctarget}\"\n" >> $myrg-$saname.tf
printf "\t resource_group_name = \"\${var.rgtarget}\"\n" >> $myrg-$saname.tf
printf "\t account_tier = \"%s\"\n" $satier >> $myrg-$saname.tf
printf "\t account_replication_type = \"%s\"\n" $sartype >> $myrg-$saname.tf
printf "\t enable_blob_encryption = \"%s\"\n" $saencrypt >> $myrg-$saname.tf
printf "\t enable_https_traffic_only = \"%s\"\n" $sahttps >> $myrg-$saname.tf
#
printf "}\n" >> $myrg-$saname.tf
#
cat $myrg-$saname.tf
done
for i in `seq 0 $count`; do
comm="echo"' $sal'" | jq '.[$i].id'"
said=`eval $comm | tr -d '"'`
comm="echo"' $sal'" | jq '.[$i].name'"
saname=`eval $comm | tr -d '"'`
echo $said
terraform state rm azurerm_storage_account.$saname 
terraform import azurerm_storage_account.$saname $said
done
