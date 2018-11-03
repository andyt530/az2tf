prefixa=`echo $0 | awk -F 'azurerm_' '{print $2}' | cut -f1 -d'.'`
tfp=`printf "azurerm_%s" $prefixa`
echo $ftp

if [ "$1" != "" ]; then
    rgsource=$1
else
    echo -n "Enter name of Resource Group [$rgsource] > "
    read response
    if [ -n "$response" ]; then
        rgsource=$response
    fi
fi

echo $TF_VAR_rgtarget
if [ "$1" != "" ]; then
    rgsource=$1
fi
at=`az account get-access-token`
bt=`echo $at | jq .accessToken | tr -d '"'`
sub=`echo $at | jq .subscription | tr -d '"'`

ris2=`printf "curl -s  -X GET -H \"Authorization: Bearer %s\" -H \"Content-Type: application/json\" https://management.azure.com/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Resources/deployments/Microsoft.Databricks?api-version=2017-05-10 " $bt $sub $rgsource`
ret2=`eval $ris2`
azr=`echo $ret2 | jq .`
echo $azr | jq .

name=`echo $azr | jq ".properties.parameters.workspaceName.value" | tr -d '"'`
id=`echo $azr | jq ".id" | tr -d '"'`
loc=`echo $azr | jq ".properties.parameters.location.value"| tr -d '"'`
rg=$rgsource
sku=`echo $azr | jq ".properties.parameters.tier.value"| tr -d '"'`
if [ "$sku" = "standard" ]; then sku="Standard" ; fi
if [ "$sku" = "premium" ]; then sku="Premium" ; fi
prefix=`printf "%s__%s" $prefixa $rg`
outfile=`printf "%s.%s__%s.tf" $tfp $rg $name`
echo $az2tfmess > $outfile
printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name >> $outfile
printf "\t name = \"%s\"\n" $name >> $outfile   
printf "\t resource_group_name = \"%s\"\n" $rg >> $outfile
printf "\t location = \"%s\"\n" $loc >> $outfile
printf "\t sku = \"%s\"\n" $sku >> $outfile
printf "}\n" >> $outfile
      
cat $outfile
statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $name`
echo $statecomm >> tf-staterm.sh
eval $statecomm
evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $name $id`
echo $evalcomm >> tf-stateimp.sh
eval $evalcomm


exit






azr=`az storage account list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        #echo $i
        saname=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
        k=`az storage account keys list --resource-group $rg --account-name $saname --query '[0].value'`
        fs=`az storage container list --account-name $saname --account-key $k`        
        jcount=`echo $fs | jq '. | length'`
        if [ "$jcount" -gt "0" ]; then
            jcount=`expr $jcount - 1`
            for j in `seq 0 $jcount`; do     
                name=`echo $fs | jq ".[(${i})].name" | tr -d '"'`
                prefix=`printf "%s__%s" $prefixa $rg`
                outfile=`printf "%s.%s__%s.tf" $tfp $rg $name`
                fsid=`printf "https://%s.blob.core.windows.net/%s" $saname $name`

                echo $az2tfmess > $outfile
                printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name >> $outfile
                printf "\t name = \"%s\"\n" $name >> $outfile   
                printf "\t resource_group_name = \"%s\"\n" $rg >> $outfile
                printf "\t storage_account_name = \"%s\"\n" $saname >> $outfile
                printf "}\n" >> $outfile
      
                cat $outfile
                statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $name`
                echo $statecomm >> tf-staterm.sh
                eval $statecomm
                evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $name $fsid`
                echo $evalcomm >> tf-stateimp.sh
                eval $evalcomm

            done
        fi
    done
fi
