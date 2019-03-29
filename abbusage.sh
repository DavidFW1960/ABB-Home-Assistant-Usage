#!/bin/bash

# Only edit the following setup lines with correct login information

# Aussie Broadband Details

abblogin=******
abbpassword=******
usageid=******

# Home Assistant Config

server=http://ipaddress:8123
token=******
entitypicture=/local/icons/abb/abb.png

# DO NOT ALTER ANYTHING BELOW THIS LINE

cookie="$(mktemp)"
curl -c $cookie -d "username=$abblogin" -d "password=$abbpassword" --url 'https://myaussie-auth.aussiebroadband.com.au/login'
abbusagestring=$(curl -b $cookie --url "https://myaussie-api.aussiebroadband.com.au/broadband/$usageid/usage")
rm $cookie

zone=$(date +"%:z")
lastup=$(echo "$abbusagestring" | jq '.["lastUpdated"]')
lastup=$(echo "$lastup" | sed 's/.$//g')
lastupdated=$(echo "$lastup" | sed 's/ /T/g')
rollover=$(echo "$abbusagestring" | jq '.["daysRemaining"]')
nextrollover=${lastupdated#?}$zone
nextrollover=$(date -d "$nextrollover+$rollover days" -Is)
nextrollover=$(echo "$nextrollover" |sed "s/${nextrollover:11:8}/00:00:00/g")
lastupdated=$lastupdated$zone
daystotal=$(echo "$abbusagestring" | jq '.["daysTotal"]')
daysremaining=$(echo "$abbusagestring" | jq '.["daysRemaining"]')
daysused=$(echo "$(($daystotal - $daysremaining + 1 ))")
abbusagestring=$(echo "$abbusagestring" | sed "s/$lastup\"/$lastupdated\",\"nextRollover\":\"$nextrollover\",\"daysUsed\":$daysused,\"friendly_name\":\"ABB Usage\",\"icon\":\"mdi:blank\",\"entity_picture\":}/g")
abbusagestring=$(echo "$abbusagestring" | sed "s/{\"usedMb/{\"state\":\"\",\"attributes\":{\"usage\":\"\",\"usedMb/g")
abbusagestring=$(echo "$abbusagestring" | sed -e "s#:}}#:\"${entitypicture}\"}}#g")

# Publish to HA with token

# echo $abbusagestring | tee abbusage.json

curl -X POST -H "Authorization: Bearer $token" \
     -H "Content-Type: application/json" \
     -d "$abbusagestring" \
     "$server"/api/states/sensor.abb_usage

