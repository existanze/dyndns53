#!/bin/bash

# This file was taken from http://willwarren.com/2014/07/03/roll-dynamic-dns-service-using-amazon-route53/
#
# I am adding to this repository in order to conform to the heroku 6 hour downtime.
# For example, if I run my crun job every 5 minutes, I don't want to call the /register_ip
# enpoint when it is not necessary.

# I understand the original script, and I am modifying basically just one call
# you can use it at your own peril

# (optional) You might need to set your PATH variable at the top here
# depending on how you run this script
#PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENPOINT="http://existanze.com/register_ip"
USERNAME="then  domain name you set in the csv"
PASSWORD="the password for the domain name you set in the csv"


# Change this if you want
COMMENT="Auto updating @ `date`"

IPPROVIDER=https://icanhazip.com/

# Get the external IP address
IP=`/usr/local/Cellar/curl/7.36.0/bin/curl -sS $IPPROVIDER`

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# Get current dir
# (from http://stackoverflow.com/a/246128/920350)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGFILE="$DIR/update-route53.log"
IPFILE="$DIR/update-route53.ip"

if ! valid_ip $IP; then
    echo "Invalid IP address: $IP" >> "$LOGFILE"
    exit 1
fi

# Check if the IP has changed
if [ ! -f "$IPFILE" ]
    then
    touch "$IPFILE"
fi

if grep -Fxq "$IP" "$IPFILE"; then
    # code if found
    echo "IP is still $IP. Exiting" >> "$LOGFILE"
    exit 0
else
    echo "IP has changed to $IP" >> "$LOGFILE"

    #I am using --location-trusted just in case you need to forward
    #the credentials in a 302 redirect like we are doing
    curl --location-trusted -u $USERNAME:$PASSWORD $ENPOINT
    echo "" >> "$LOGFILE"

fi

# All Done - cache the IP address for next time
echo "$IP" > "$IPFILE"
