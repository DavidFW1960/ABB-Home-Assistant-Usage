#!/bin/bash

###### Only edit the following setup lines with correct login information #####

# Aussie Broadband Details

abblogin=******
abbpassword=******
usageid=******

# Home Assistant Config

server=http://ipaddress:8123
token=******
entitypicture=/local/icons/abb/abb.png

###### DO NOT ALTER ANYTHING BELOW THIS LINE ######

# Retrieving ABB Usage Data
cookie="$(mktemp)"
curl -c $cookie -d "username=$abblogin" -d "password=$abbpassword" --url 'https://myaussie-auth.aussiebroadband.com.au/login'
abbusagestring=$(curl -b $cookie --url "https://myaussie-api.aussiebroadband.com.au/broadband/$usageid/usage")
rm $cookie

# Get Timezone
zone=$(date +"%:z")

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

# Build ISO Format Dates for lastUpdated and nextRollover (midnight on rollover day)
lastUpdated=$(echo "$lastUpdated" | sed 's/ /T/g')$zone
nextRollover=$(date -d "$lastUpdated+$daysRemaining days" -Is)
nextRollover=$(echo "$nextRollover" |sed "s/${nextRollover:11:8}/00:00:00/g")

# Build daysUsed from daysTotal and daysRemaining
daysUsed=$(echo "$(($daysTotal - $daysRemaining))")

# Build JSON output
abbusagestring='{"state":"","attributes":{"usage":"","usedMb":'"$usedMb"',"downloadedMb":'"$downloadedMb"',"uploadedMb":'"$uploadedMb"',"remainingMb":'"$remainingMb"',"daysTotal":'"$daysTotal"',"daysRemaining":'"$daysRemaining"',"lastUpdated":"'"$lastUpdated"'","nextRollover":"'"$nextRollover"'","daysUsed":'"$daysUsed"',"friendly_name":"ABB Usage","icon":"mdi:blank","entity_picture":"'"$entitypicture"'"}}'


# Publish to HA with token

curl -X POST -H "Authorization: Bearer $token" \
     -H "Content-Type: application/json" \
     -d "$abbusagestring" \
     "$server"/api/states/sensor.abb_usage
