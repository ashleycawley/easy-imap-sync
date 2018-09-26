#!/bin/bash
#
# Author: Ashley Cawley // @ashleycawley // ash@ashleycawley.co.uk
#
# This script will be a front-facing UI addon to the imapsync tool
# reducing the need for the user to know the correct syntax and
# layout required to use that command this script will instead
# prompt the user for the correct information in plain english.
#
## Setting Variables
CONTINUE=yes
#
## Functions
function MAILSYNC {
imapsync --host1 $SOURCE --user1 $EMAIL --password1 \"$PASSWORD\" --host2 $DESTINATION --user2 $EMAIL --password2 \"$PASSWORD\"
}
#
function CLEANUP {
rm -f email.tmp email.tmp2 mx-lookup.tmp
}
# Setting Constants
declare -r U_CMDS="imapsync"
#
# Sanity checking to see if commands and tools are available in the environment
for the_command in $U_CMDS
	do
		type -P $the_command >> /dev/null && : || {
        echo -e "$the_command not found in PATH ." >&2
        exit 1
    }
done
#
## Normal Script Begins...
while [ $CONTINUE = "yes" ]
do
read -e -p "What is the email address you are migrating?: " EMAIL
read -e -p "What is its password?: " PASSWORD
read -e -p "What is IP or Hostname of the Source Email Server?: " SOURCE
read -e -p "What is the IP or Hostname of the Destination Email Server?: " DESTINATION

# Save EMAIL variable to file
echo $EMAIL > email.tmp

# Removes the user part and just extracts the domain name
awk -F@ 'END{for(i in A)print A[i],i}{A[$2]}' email.tmp > email.tmp2

# Removes the space infront of the domain name
sed -i s/' '//g email.tmp2

# Pulls in contents of a file in to variable
DOMAIN=$(cat email.tmp2)

# Performs a MX Lookup to see if it is with Google
dig MX $DOMAIN > mx-lookup.tmp

# Searches MX Record Results to see if it contains the word google
grep -i "google" mx-lookup.tmp

if [ `echo $?` == 0 ]
	then
		imapsync --host1 $SOURCE --port1 993 --ssl1 --user1 $EMAIL --password1 '$PASSWORD' --host2 $DESTINATION --port2 993 --ssl2 --user2 $EMAIL --password2 '$PASSWORD'
		CLEANUP
		echo && echo "Finishing up..." && echo
		exit 0

fi

MAILSYNC # Function defined toward the top.
CLEANUP
echo && echo "Finishing up..." && sleep 2 && echo

CONTINUE=no

read -e -p "Would you like to transfer anymore email accounts on the same domain name? ( 'yes' or 'no' ): " MORE
done

while [ $MORE = "yes" ]
do
read -e -p "What is the email address you are migrating?: " EMAIL
read -e -p "What is its password?: " PASSWORD

MAILSYNC # Function defined toward the top.

echo && echo "Finishing up..." && sleep 2 && echo

read -e -p "Would you like to transfer anymore email accounts on the same domain name? ( 'yes' or 'no' ): " MORE
done
	exit 0
