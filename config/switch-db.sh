#!/bin/bash

if [[ "$1" = "" ]]
then
	echo "Usage: $0 dbname";
	exit 0;
fi


FILE="~/Sites/www/src/wp-config.php"
DB_NAME="$1"


echo "Commenting out all defined DB_NAME lines"
sed -i.bak '/DB_NAME/ s/^define/\/\/define/' $FILE;
#sleep 5;
echo "DB_NAME SET: $DB_NAME"
sed -i.bak "/$DB_NAME/ s/^\/\/define/define/" $FILE;

exit 0;
