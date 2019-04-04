﻿#!/bin/bash

if [[ -e "abbcreds.json" ]]
then
  abbcreds=$(cat abbcreds.json)
else
  echo "EXITING. *****Credentials not found.***** Please run abbcreds.sh script to set up user details"
  exit
fi

# Aussie Broadband Details
abblogin=$(echo "$abbcreds" | jq '.["abblogin"]')
abblogin=$(echo "$abblogin" | sed 's/.$//g')
abblogin=$(echo $abblogin | cut -c2-)
abbpassword=$(echo "$abbcreds" | jq '.["abbpassword"]')
abbpassword=$(echo "$abbpassword" | sed 's/.$//g')
abbpassword=$(echo $abbpassword | cut -c2-)
usageid=$(echo "$abbcreds" | jq '.["usageid"]')
usageid=$(echo "$usageid" | sed 's/.$//g')
usageid=$(echo $usageid | cut -c2-)

# Home Assistant Config
server=$(echo "$abbcreds" | jq '.["server"]')
server=$(echo "$server" | sed 's/.$//g')
server=$(echo $server | cut -c2-)
token=$(echo "$abbcreds" | jq '.["token"]')
token=$(echo "$token" | sed 's/.$//g')
token=$(echo $token | cut -c2-)
entitypicture=$(echo "$abbcreds" | jq '.["entitypicture"]')
entitypicture=$(echo "$entitypicture" | sed 's/.$//g')
entitypicture=$(echo $entitypicture | cut -c2-)

# Retrieving ABB Usage Data
#cookie="$(mktemp)"
cookie=abbcookie.txt
#curl -c $cookie -d "username=$abblogin" -d "password=$abbpassword" --url 'https://myaussie-auth.aussiebroadband.com.au/login' > abbtoken.json
abbusagestring=$(curl -b $cookie --url "https://myaussie-api.aussiebroadband.com.au/broadband/$usageid/usage")
#rm $cookie

# Get Variables from String
usedMb=$(echo "$abbusagestring" | jq '.["usedMb"]')
downloadedMb=$(echo "$abbusagestring" | jq '.["downloadedMb"]')
uploadedMb=$(echo "$abbusagestring" | jq '.["uploadedMb"]')
remainingMb=$(echo "$abbusagestring" | jq '.["remainingMb"]')
daysTotal=$(echo "$abbusagestring" | jq '.["daysTotal"]')
daysRemaining=$(echo "$abbusagestring" | jq '.["daysRemaining"]')
lastUpdated=$(echo "$abbusagestring" | jq '.["lastUpdated"]')

# Remove leading and trailing "'s
lastUpdated=$(echo "$lastUpdated" | sed 's/.$//g')
lastUpdated=$(echo $lastUpdated | cut -c2-)

# Calculate Dates
todaydatetime=$(date -Is)
lastUpdatedISO=$(echo "$todaydatetime" |sed "s/${todaydatetime:11:8}/${lastUpdated:11:8}/g")
lastUpdated=$(date -d "$lastUpdated" +%s)
daysRemainingEpochs=$(($daysRemaining*86400))
nextRollover=$(($lastUpdated + $daysRemainingEpochs))
nextRollover=$(date -d @"$nextRollover" -Is)
nextRollover=$(echo "$nextRollover" |sed "s/${nextRollover:11:8}/00:00:00/g")
lastUpdated=$lastUpdatedISO

####### ONLY FOR HASSIO.... COMMENT OUT FOR OTHERS #######
nextRollover=$(echo "$nextRollover" |sed "s/.\{2\}$/:&/")
lastUpdated=$(echo "$lastUpdated" |sed "s/.\{2\}$/:&/")
####### END FOR HASSIO ONLY COMMENTS #######

# Build daysUsed from daysTotal and daysRemaining
daysUsed=$(echo "$(($daysTotal - $daysRemaining))")

# Build JSON output
abbusagestring='{"state":"","attributes":{"usage":"","usedMb":'"$usedMb"',"downloadedMb":'"$downloadedMb"',"uploadedMb":'"$uploadedMb"',"remainingMb":'"$remainingMb"',"daysTotal":'"$daysTotal"',"daysRemaining":'"$daysRemaining"',"lastUpdated":"'"$lastUpdated"'","nextRollover":"'"$nextRollover"'","daysUsed":'"$daysUsed"',"friendly_name":"ABB Usage","icon":"mdi:blank","entity_picture":"'"$entitypicture"'"}}'

# Publish to HA with token

curl -X POST -H "Authorization: Bearer $token" \
     -H "Content-Type: application/json" \
     -d "$abbusagestring" \
     "$server"/api/states/sensor.abb_usage