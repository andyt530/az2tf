"converting $1"
sed -i .bak -e 's/\"True\"/true/g' $1 
sed -i .bak -e 's/\"False\"/false/g' $1 
rm -f *.bak
