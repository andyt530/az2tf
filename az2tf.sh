if [ "$1" != "" ]; then
    mysub=$1
else
    echo -n "Enter id of Subscription [$mysub] > "
    read response
    if [ -n "$response" ]; then
        mysub=$response
    fi
fi
comm[1]="./scripts/01-azurerm_resource_group.sh"
comm[2]="./scripts/03-azurerm_route_table.sh"
comm[6]="./scripts/02-azurerm_availability_set.sh $myrg"
comm[5]="./scripts/04-azurerm_network_security_group.sh $myrg"
comm[3]="./scripts/06-azurerm_subnet.sh $myrg"
comm[4]="./scripts/08-azurerm_virtual_network.sh $myrg"
comm[7]="./scripts/11-azurerm_managed_disk.sh $myrg"
comm[8]="./scripts/12-azurerm_storage_account.sh $myrg"
comm[9]="./scripts/14-azurerm_public_ip.sh $myrg"
comm[10]="./scripts/16-azurerm_network_interface.sh $myrg"
comm[11]="./scripts/20-azurerm_virtual_machine.sh $myrg"
source ./setup-vars.sh
export ARM_SUBSCRIPTION_ID=""
export ARM_CLIENT_SECRET=""
export ARM_TENANT_ID=""
export ARM_SUBSCRIPTION_ID=""
export TF_VAR_rgtarget=$myrg
az account set -s $mysub
#echo "Clean Dir"
#./cleanup.sh
#echo "Clean terraform"
#./cleanstate.sh
#az account set -s $ARM_SUBSCRIPTION_ID
rm terraform*.backup
cp stub/*.tf .
for j in `seq 11 11`; do      # 7 - managed disk - needs work
    echo $i
    trgs=`az group list`
    count=`echo $trgs | jq '. | length'`
    if [ "$count" -gt "0" ]; then
        count=`expr $count - 1`
        for i in `seq 0 $count`; do
            myrg=`echo $trgs | jq ".[(${i})].name" | tr -d '"'`
            echo $i of $count  RG=$myrg
            mkdir -p tf.$myrg
            docomm=`echo ${comm[$j]} $myrg`
            #echo $docomm
            eval $docomm
            cp *_*-*.tf tf.$myrg
        done
    fi
    rm terraform*.backup
done
#
#Cleanup
rm *cloud-shell-storage*.tf
states=`terraform state list | grep cloud-shell-storage`
echo $states
terraform state rm $states
#
#terraform state list
echo "Terraform Plan ..."
terraform plan .

