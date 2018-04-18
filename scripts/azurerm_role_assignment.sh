tfp="azurerm_role_assignment"
prefixa="ras"
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
azr=`az role assignment list`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].name"`
        echo name - $name
        scope=`echo $azr | jq ".[(${i})].properties.scope"`
        rdid=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        prid=`echo $azr | jq ".[(${i})].properties.principalId"`
        roledefid=`echo $azr | jq ".[(${i})].properties.roleDefinitionId"`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        rg="roleAssignments"
        prefix=`printf "%s_%s" $prefixa $rg`
        
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $rdid > $prefix-$rdid.tf
        echo "name = $name"  >> $prefix-$rdid.tf
        printf "role_definition_id = %s\n" $roledefid >> $prefix-$rdid.tf
        printf "principal_id = %s\n" $prid >> $prefix-$rdid.tf
        printf "scope = %s\n" $scope  >> $prefix-$rdid.tf
   
        printf "}\n" >> $prefix-$rdid.tf
        
        cat $prefix-$rdid.tf
        statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $rdid`
        eval $statecomm
        evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $rdid $id`
        eval $evalcomm
        
        
    done
fi
