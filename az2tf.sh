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
res[13]="azurerm_lb"   # move to end ?

pfx[14]="lbnr"
res[14]="azurerm_lb_nat_rule"
pfx[15]="lbnp"
res[15]="azurerm_lb_nat_pool"


pfx[16]="lbbe"
res[16]="azurerm_lb_backend_address_pool"
pfx[17]="lbpr"
res[17]="azurerm_lb_probe"
pfx[18]="lbr"
res[18]="azurerm_lb_rule"


pfx[19]="vm"
res[19]="azurerm_virtual_machine"
pfx[20]="lck"
res[20]="azurerm_management_lock"

pfx[51]="rdf"
res[51]="azurerm_role_definition"
pfx[52]="ras"
res[52]="azurerm_role_assignment"
pfx[53]="pdf"
res[53]="azurerm_policy_definition"
pfx[54]="pas"
res[54]="azurerm_policy_assignment"

#
# uncomment following line if you want to use an SPN login
#../setup-env.sh


export ARM_SUBSCRIPTION_ID="$mysub"

az account set -s $mysub

if [ "$2" != "" ]; then
    # check provided resource group exists in subscription
    exists=`az group exists -g $2`
    if  ! $exists ; then
        echo "Resource Group $2 does not exists in subscription $mysub  Exit ....."
        exit
    fi
    
fi

# cleanup from any previous runs
rm -f terraform*.backup
rm -f tf*.sh
cp ../stub/*.tf .
echo "terraform init"
terraform init

# subscription level stuff - roles & policies
for j in `seq 51 54`; do
    
    docomm="../scripts/${res[$j]}.sh $mysub"
    echo $docomm
    eval $docomm
done

# loop through providers
for j in `seq 1 20`; do
    if [ "$2" != "" ]; then
        myrg=$2
        echo $myrg
        docomm="../scripts/${res[$j]}.sh $myrg"
        echo $docomm
        eval $docomm
    else
        trgs=`az group list`
        count=`echo $trgs | jq '. | length'`
        if [ "$count" -gt "0" ]; then
            count=`expr $count - 1`
            for i in `seq 0 $count`; do
                myrg=`echo $trgs | jq ".[(${i})].name" | tr -d '"'`
                echo -n $i of $count " "
                #pwd
                docomm="../scripts/${res[$j]}.sh $myrg"
                echo $docomm
                eval $docomm
                
            done
        fi
    fi
    rm terraform*.backup > /dev/null
done

#
# Cleanup Cloud Shell
rm -f *cloud-shell-storage*.tf
states=`terraform state list | grep cloud-shell-storage`
echo $states
terraform state rm $states
#
echo "Terraform Plan ..."
terraform plan .
exit