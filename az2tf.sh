export az2tfmess="# File auto generate by az2tf see https://github.com/andyt530/az2tf"
if [ "$1" != "" ]; then
    mysub=$1
else
    echo -n "Enter id of Subscription [$mysub] > "
    read response
    if [ -n "$response" ]; then
        mysub=$response
    fi
fi

echo "Checking Subscription $mysub exists ..."
isok="no"
subs=`az account list --query '[].id' | jq '.[]' | tr -d '"'`
for i in `echo $subs`
do
    if [ "$i" = "$mysub" ] ; then
        echo "Found subscription $mysub proceeding ..."
        isok="yes"
    fi
done
if [ "$isok" != "yes" ]; then
    echo "Could not find subscription with ID $mysub"
    exit
fi

export ARM_SUBSCRIPTION_ID="$mysub"
az account set -s $mysub

mkdir -p tf.$mysub
cd tf.$mysub
rm -rf .terraform

if [ "$2" != "" ]; then
    myrg=$2
    ../scripts/resources.sh $myrg
else
    ../scripts/resources.sh
fi

pfx[1]="null"
res[1]="azurerm_resource_group"
pfx[2]="resource"
res[2]="azurerm_availability_set"
pfx[3]="resource"
res[3]="azurerm_route_table"
pfx[4]="resource" 
res[4]="azurerm_application_security_group"
pfx[5]="resource"
res[5]="azurerm_network_security_group"
pfx[6]="resource"
res[6]="azurerm_virtual_network"
pfx[7]="resource"
res[7]="azurerm_subnet"
pfx[8]="resource"
res[8]="azurerm_virtual_network_peering"
pfx[9]="resource"
res[9]="azurerm_key_vault"
pfx[10]="resource"
res[10]="azurerm_managed_disk"
pfx[11]="resource"
res[11]="azurerm_storage_account"
pfx[12]="resource"
res[12]="azurerm_public_ip"
pfx[13]="resource"
res[13]="azurerm_network_interface"

pfx[14]="resource"
res[14]="azurerm_lb"   # move to end ?
pfx[15]="resource"
res[15]="azurerm_lb_nat_rule"
pfx[16]="resource"
res[16]="azurerm_lb_nat_pool"
pfx[17]="resource"
res[17]="azurerm_lb_backend_address_pool"
pfx[18]="resource"
res[18]="azurerm_lb_probe"
pfx[19]="resource"
res[19]="azurerm_lb_rule"
pfx[20]="resource"
res[20]="azurerm_local_network_gateway"
pfx[21]="resource"
res[21]="azurerm_virtual_network_gateway"
pfx[22]="resource"
res[22]="azurerm_virtual_network_gateway_connection"
pfx[23]="resource"
res[23]="azurerm_express_route_circuit"
pfx[24]="resource"
res[24]="azurerm_express_route_circuit_authorization"
pfx[25]="resource"
res[25]="azurerm_express_route_circuit_peering"


pfx[26]="resource"
res[26]="azurerm_container_registry"
pfx[27]="resource"
res[27]="azurerm_kubernetes_cluster"
pfx[28]="resource"
res[28]="azurerm_recovery_services_vault"

pfx[29]="resource"
res[29]="azurerm_virtual_machine"
pfx[30]="az lock list"
res[30]="azurerm_management_lock"
pfx[31]="resource"
res[31]="azurerm_automation_account"
pfx[32]="resource"
res[32]="azurerm_log_analytics_workspace"
pfx[33]="resource"
res[33]="azurerm_log_analytics_solution"
pfx[34]="resource"
res[34]="azurerm_image"
pfx[35]="resource"
res[35]="azurerm_key_vault_secret"
pfx[36]="resource"
res[36]="azurerm_network_watcher"


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
if [ "$2" = "" ]; then
    for j in `seq 51 54`; do
        
        docomm="../scripts/${res[$j]}.sh $mysub"
        echo $docomm
        eval $docomm
    done
fi


# loop through providers
for j in `seq 1 36`; do
    if [ "$2" != "" ]; then
        # RG specified
        myrg=$2
        echo $myrg
        docomm="../scripts/${res[$j]}.sh $myrg"
        echo "$j $docomm"
        eval $docomm
    else
        c1=`echo ${pfx[${j}]}`
        gr=`printf "%s-" ${res[$j]}`
        echo $gr
        #echo $c1
        case "$c1" in
            "resource")
                lc="1"
                tc2=`cat resources2.txt | grep $gr | wc -l`
                for l in `cat resources2.txt | grep $gr` ; do
                    echo -n $lc of $tc2 " "
                    myrg=`echo $l | cut -d':' -f1`
                    prov=`echo $l | cut -d':' -f2`
                    #echo "debug $j prov=$prov  res=${res[$j]}"
                    docomm="../scripts/${res[$j]}.sh $myrg"
                    echo "$j $docomm"
                    eval $docomm
                    lc=`expr $lc + 1`
                done
            ;;
            "null")
                trgs=`az group list`
                count=`echo $trgs | jq '. | length'`
                if [ "$count" -gt "0" ]; then
                    count=`expr $count - 1`
                    for i in `seq 0 $count`; do
                        myrg=`echo $trgs | jq ".[(${i})].name" | tr -d '"'`
                        echo -n $i of $count " "
                        docomm="../scripts/${res[$j]}.sh $myrg"
                        echo "$j $docomm"
                        eval $docomm
                        
                    done
                fi
            ;;
            *)
                comm=`printf "%s --query '[].resourceGroup' | jq '.[]' | sort -u" "$c1"`
                comm2=`printf "%s --query '[].resourceGroup' | jq '.[]' | sort -u | wc -l" "$c1"`
                tc=`eval $comm2`
                tc=`echo $tc | tr -d ' '`
                trgs=`eval $comm`
                count=`echo ${#trgs}`
                if [ "$count" -gt "0" ]; then
                    c5="1"
                    for j2 in `echo $trgs`; do
                        echo -n "$c5 of $tc "
                        docomm="../scripts/${res[$j]}.sh $j2"
                        echo "$j $docomm"
                        eval $docomm
                        c5=`expr $c5 + 1`
                    done
                fi
            ;;
        esac
    fi
    rm -f terraform*.backup
done


#
echo "Cleanup Cloud Shell"
rm -f *cloud-shell-storage*.tf
states=`terraform state list | grep cloud-shell-storage`
echo $states
terraform state rm $states
#
echo "Terraform Plan ..."
terraform plan .
exit
