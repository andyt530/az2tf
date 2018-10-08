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

pfx[1]="az group list"
res[1]="azurerm_resource_group"
pfx[2]="az lock list"
res[2]="azurerm_management_lock"

res[51]="azurerm_role_definition"
res[52]="azurerm_role_assignment"
res[53]="azurerm_policy_definition"
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

# top level stuff
j=1
if [ "$2" != "" ]; then
    trgs=`az group list --query "[?name=='$myrg']"`
else
    trgs=`az group list`
fi

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

for j in `seq 2 2`; do
    c1=`echo ${pfx[${j}]}`
    gr=`printf "%s-" ${res[$j]}`
    #echo c1=$c1 gr=$gr
    comm=`printf "%s --query '[].resourceGroup' | jq '.[]' | sort -u" "$c1"`
    comm2=`printf "%s --query '[].resourceGroup' | jq '.[]' | sort -u | wc -l" "$c1"`
    #echo comm=$comm2
    tc=`eval $comm2`
    #echo tc=$tc
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
    
done

# loop through providers


for com in `ls ../scripts/*_azurerm*.sh | cut -d'/' -f3 | sort -g`; do
    #for com in `ls ../scripts/*_azurerm*.sh | grep 290 | cut -d'/' -f3 | sort -g`; do
    if [ "$2" != "" ]; then
        myrg=$2
        #echo $myrg
        docomm="../scripts/$com $myrg"
        echo "$j $docomm"
        eval $docomm
    else
        gr=`echo $com | awk -F 'azurerm_' '{print $2}' | awk -F '.sh' '{print $1}'`
        echo $gr
        lc="1"
        tc2=`cat resources2.txt | grep $gr | wc -l`
        for l in `cat resources2.txt | grep $gr` ; do
            echo -n $lc of $tc2 " "
            myrg=`echo $l | cut -d':' -f1`
            prov=`echo $l | cut -d':' -f2`
            #echo "debug $j prov=$prov  res=${res[$j]}"
            docomm="../scripts/$com $myrg"
            echo "$j $docomm"
            eval $docomm
            lc=`expr $lc + 1`
        done
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
