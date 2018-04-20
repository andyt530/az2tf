if [ "$1" != "" ]; then
    mysub=$1
else
    echo -n "Enter id of Subscription [$mysub] > "
    read response
    if [ -n "$response" ]; then
        mysub=$response
    fi
fi

mkdir -p tf.$mysub
cd tf.$mysub

pfx[1]="rg"
res[1]="azurerm_resource_group"
pfx[2]="rtb"
res[2]="azurerm_route_table"
pfx[3]="nsg"
res[3]="azurerm_network_security_group"
pfx[4]="vnet"
res[4]="azurerm_virtual_network"
pfx[5]="sub"
res[5]="azurerm_subnet"
pfx[6]="vnp"
res[6]="azurerm_virtual_network_peering"
pfx[7]="kv"
res[7]="azurerm_key_vault"
pfx[8]="avs"
res[8]="azurerm_availability_set"
pfx[9]="md"
res[9]="azurerm_managed_disk"
pfx[10]="stor"
res[10]="azurerm_storage_account"
pfx[11]="pip"
res[11]="azurerm_public_ip"
pfx[12]="nic"
res[12]="azurerm_network_interface"
pfx[13]="lb"
res[13]="azurerm_lb"
pfx[14]="vm"
res[14]="azurerm_virtual_machine"
pfx[15]="lck"
res[15]="azurerm_management_lock"

pfx[51]="rdf"
res[51]="azurerm_role_definition"
pfx[52]="ras"
res[52]="azurerm_role_assignment"

source ../setup-vars.sh
export ARM_SUBSCRIPTION_ID=""
export ARM_CLIENT_SECRET=""
export ARM_TENANT_ID=""
export ARM_SUBSCRIPTION_ID="$mysub"

az account set -s $mysub
#echo "Clean Dir"
#./cleanup.sh
#echo "Clean terraform"
#./cleanstate.sh
#az account set -s $ARM_SUBSCRIPTION_ID

rm terraform*.backup
rm tf*.sh
cp ../stub/*.tf .
echo "init"
terraform init


for j in `seq 51 52`; do

docomm="../scripts/${res[$j]}.sh $mysub"
    echo $docomm
    eval $docomm
done


for j in `seq 1 15`; do  


    trgs=`az group list`
    count=`echo $trgs | jq '. | length'`
    if [ "$count" -gt "0" ]; then
        count=`expr $count - 1`
        for i in `seq 0 $count`; do
            myrg=`echo $trgs | jq ".[(${i})].name" | tr -d '"'`
            echo $i of $count  RG=$myrg
            #pwd
            docomm="../scripts/${res[$j]}.sh $myrg"
            echo $docomm
            eval $docomm
            
        done
    fi
    rm terraform*.backup > /dev/null
done

#
#Cleanup Cloud Shell
rm *cloud-shell-storage*.tf
states=`terraform state list | grep cloud-shell-storage`
echo $states
terraform state rm $states
#
#terraform state list
echo "Terraform Plan ..."
terraform plan .
exit