for i in `ls *.tf` ;do
#j=`echo $i | cut -f1 -d '.'`
#p $i $j.tf12
./convert.sh $i
done
