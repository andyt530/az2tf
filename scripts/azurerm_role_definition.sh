tfp="azurerm_role_definition"
prefixa="rdf"
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
azr=`az role definition list --custom-role-only`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].properties.roleName"`
        rdid=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        desc=`echo $azr | jq ".[(${i})].properties.description"`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        rg="roleDefinitions"

        scopes=`echo $azr | jq ".[(${i})].properties.assignableScopes"`
        actions=`echo $azr | jq ".[(${i})].properties.permissions[0].actions"`
        nactions=`echo $azr | jq ".[(${i})].properties.permissions[0].notActions"`

        prefix=`printf "%s_%s" $prefixa $rg`
        

 #       printf "data \"azurerm_subscription\" \"primary\" {}\n\n" $prefix-$rdid.tf
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $rdid > $prefix-$rdid.tf
        echo "name = $name"  >> $prefix-$rdid.tf
        printf "role_definition_id = \"%s\"\n" >> $prefix-$rdid.tf
        echo "description = $desc" >> $prefix-$rdid.tf
#        printf "scope = \"\${data.azurerm_subscription.primary.id}\"\n"  >> $prefix-$rdid.tf
#        printf "scope = \"/subscriptions/%s\"\n" $rgsource >> $prefix-$rdid.tf
        printf "scope = \"\"\n"  >> $prefix-$rdid.tf
        #
        printf "permissions { \n" >> $prefix-$rdid.tf
    
        printf "actions = \n" $actions >> $prefix-$rdid.tf
        printf "%s\n" $actions >> $prefix-$rdid.tf
    
        printf "not_actions = \n" $nactions >> $prefix-$rdid.tf
        printf "%s\n" $nactions >> $prefix-$rdid.tf
    
        printf "} \n" >> $prefix-$rdid.tf
        
        printf "assignable_scopes =  \n" >> $prefix-$rdid.tf
        printf "%s\n" $scopes >> $prefix-$rdid.tf
       
        printf "}\n" >> $prefix-$rdid.tf
        
        cat $prefix-$rdid.tf
        statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $rdid`
        eval $statecomm
        evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $rdid $id`
        eval $evalcomm
        
        
    done
fi
