for i in `terraform state list`
do
terraform state rm $i
done
