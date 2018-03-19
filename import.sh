./cleanup.sh
for k in `ls 0*-*.sh`
do
echo $k
./$k
done
