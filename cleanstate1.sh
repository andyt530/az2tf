for i in `terraform state list | grep azurerm_availability_set`
do
terraform state rm $i
done
