#!/bin/sh

# Force a rotation of local admin password on a specific device 
# Version 1.0

# Check this page to create a OAuth Client : https://docs.vmware.com/en/VMware-Workspace-ONE-UEM/services/UEM_ConsoleBasics/GUID-UsingUEMFunctionalityWithRESTAPI.html

# REST API FQDN
uemAPI="asXXX.awmdm.com"

# Token URLs for OAuth 2.0 Support
uemTokenURL="https://emea.uemauth.vmwservices.com/connect/token"

# OAuth Client to Use for API Commands
oauth_client_ID="012345678901234567890123456789012"
oauth_client_secret="01234567890123456789012345678901"

# Prepare headers for POST
declare -a curlHeaders=('-H' "Content-Type: multipart/form-data" '--form' "grant_type=client_credentials" '--form' "client_id=$oauth_client_ID" '--form' "client_secret=$oauth_client_secret")
# Get UEM Acccess Token
uemAuthTokenFull=`curl -s --request POST "${curlHeaders[@]}" "$uemTokenURL"`
uemAuthToken=$(echo $uemAuthTokenFull | grep -o '"access_token":"[^"]*' | awk -F ':"' '{print $2}')

# Prepare headers for GET
declare -a curlHeaders2=('-H' "Content-Type: application/json" '-H' "Accept: application/json;version=2" '-H' "Authorization: Bearer $uemAuthToken")

# Prepare headers for POST
declare -a curlHeaders3=('-H' "Content-Type: application/json" '-H' "Accept: application/json;version=1" '-H' "Authorization: Bearer $uemAuthToken" '-H' "Content-Length: 0")


while true; do

	# Ask device informations
	echo "---"
	echo "Device selection, 1 by serial number, 2 by ID"
	printf "Enter a number : "

	read menu

	case "$menu" in
    	1)
    		printf "Enter a serial number : "
    		read devSerial
        	echo "---"
        	printf "Serial number is $devSerial, correct ? Y/N "
			read ValidSerial
			if [ "$ValidSerial" == "Y" ] || [ "$ValidSerial" == "y" ]; then
				# Get DeviceID from Serial Number
				devIDLong=`curl -s -X GET "${curlHeaders2[@]}" "https://$uemAPI/API/mdm/devices/?searchBy=Serialnumber&id=$devSerial"`
				devID=`echo ${devIDLong: -54: 6}`
				if [ -n "$devID" ]; then
					echo "---"
					echo "Ok, it's $devID, let's roll !'"
					break
				else 
					echo "can't find this device, sorry, back to the start"
				fi
			elif [ "$ValidSerial" == "N" ] || [ "$ValidSerial" == "n" ]; then	
				echo "Here we go again."
			fi
			;;
		2)
			printf "Enter a device ID : "
			read devID
			echo "---"
			printf "Device ID is $devID, correct ? Y/N "
			read ValidID
			if [ "$ValidID" == "Y" ] || [ "$ValidID" == "y" ]; then
				echo "---"
				echo "Ok it's $devID, let's roll !'"
				break
			elif [ "$ValidID" == "N" ] || [ "$ValidID" == "n" ]; then	
				echo "Here we go again."
			fi
			;;
		*)
			echo "Please make a choice, we're wasting time..."
			;;
	esac
done

# Get DeviceUUID from DeviceID
devUUIDLong=`curl -s -X GET "${curlHeaders2[@]}" "https://$uemAPI/API/mdm/devices/$devID"`
devUUID=`echo ${devUUIDLong: -38: 36}`

# Rotate the admin password
curl -s -X POST "${curlHeaders3[@]}" "https://$uemAPI/API/mdm/devices/$devID/commands?command=RotateDEPAdminPassword"

# Wait a little to get the new password
for ((i = 1; i <= 4; i++)); do
	printf " "
	sleep 0.5
	printf ". "
	sleep 0.5
	printf ".. "
	sleep 0.5
	printf "..."
	sleep 0.5
	printf  "Wait for the new password"
	sleep 0.5
	printf "..."	
	sleep 0.5
	printf " .."
	sleep 0.5
	printf " ."
done

# Get admin infos 
ladminInfos=`curl -s -X GET "${curlHeaders2[@]}" "https://$uemAPI/API/mdm/devices/$devUUID/security/managed-admin-information"`
previous_password=$(echo "$ladminInfos" | grep -o '"previous_password":"[^"]*' | awk -F'"previous_password":"' '{print $2}')
current_password=$(echo "$ladminInfos" | grep -o '"current_password":"[^"]*' | awk -F'"current_password":"' '{print $2}')
echo ""
echo "---"
echo "Previous password was $previous_password"
echo "---"
echo "Current password is $current_password"
exit 0
