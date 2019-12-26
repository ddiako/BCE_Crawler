#!/bin/bash
#------------------------------------------------
# BCE CEO CRAWLER
#           by ddiako
#------------------------------------------------

# First, you must install the html2text tool from apt
#CURLPROXY="--proxy <TLD>:<PORT>"
CURLPROXY=""

OUPUT="real_listing.csv"

if [[ $# -ne 1 ]]; then
    echo -e "Syntax:\n\t./extract_ceo.bash <BCENUMBERS_LIST>"
    exit 1
fi

echo "" > $OUPUT

while read LINE
do
	tmpfile=`mktemp /tmp/bcetmp-XXXXXX`
	tmpfile2=`mktemp /tmp/bceceotmp-XXXXXX`
	
	# EXTRACT BCE NUMBER FROM CSV
	bce=`echo $LINE | sed 's/\.//g'`

	# DUMP BCE INFO TO TEMP FILE
	curl $CURLPROXY -H "$(cat curl_parameter)" "http://kbopub.economie.fgov.be/kbopub/zoeknummerform.html?lang=en&nummer=$bce&actionLu=Recherche" -o $tmpfile

	# EXTRACT LEGAL PERSONS FROM DUMP TO NEW TEMP FILE
	cat $tmpfile | sed -n '/Legal functions/,/Proof of professional skills and basic knowledge of enterprise governance/{//d;p}' | html2text | grep ',' | grep -v '[0-9]' | awk -F',' '{print $2 $1}' > $tmpfile2

	# EXPORT REAL LISTING FROM LIVE DATA DUMP
	while read CEO
	do
		# TEST IF LEGAL PERSON IS DEFINED AT BCE
		echo $CEO | grep -q SMEsFPS
		if [ $? != 0 ]
		then
			echo "$bce;$CEO" >> $OUTPUT
		else
			echo "$bce;NO DATA AVAILABLE" >> $OUTPUT
		fi
	done < $tmpfile2
	rm $tmpfile $tmpfile2
done < $1
