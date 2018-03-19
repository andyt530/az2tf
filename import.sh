if [ "$1" != "" ]; then
myrg=$1
else
echo -n "Enter name of Resource Group [$rgsource] > "
read response
if [ -n "$response" ]; then
     myrg=$response
fi
fi
az account set -s $ARM_SUBSCRIPTION_ID
mkdir tf.$myrg
source ./setup-env.sh
./cleanup.sh
./scripts/01-rg.sh $myrg
./scripts/04-nsg.sh $myrg
./scripts/06-subnets.sh $myrg
./scripts/08-vnet.sh $myrg
./scripts/12-stor.sh $myrg
./scripts/14-pip.sh $myrg
./scripts/16-nic.sh $myrg
./scripts/20-vm.sh $myrg
terraform state list
echo "Terraform Plan ..."
terraform plan .
cp *-*.tf tf.$myrg
