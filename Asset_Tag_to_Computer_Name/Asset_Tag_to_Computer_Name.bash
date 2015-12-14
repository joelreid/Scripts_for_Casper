#!/bin/bash

# Asset_Tag_to_Computer_Name.bash
#  Copyright (c) Joel Reid 2015
#  Distributed under the MIT License (terms at http://opensource.org/licenses/MIT)

echo "$(date '+%Y-%m-%d %H:%M:%S') starting script, 'Asset_Tag_to_Computer_Name.bash'";

# config _________________________________________
jssURL='https://YOUR.JSS.URL:8443';
jssUser='yourapiuser';
jssPass='apiuserpassword';
# set to 0 to ignore empty asset tag and exit. set >0 to cause parent jss policy run to log as failed.
failIfEmpty=0;
# setting prefix or suffix here will not modify the asset tag, just the resulting computer name
prefix="";
suffix="";


# main ___________________________________________

problems=0;
echo -n "getting local UDID: ";
udid="$(system_profiler SPHardwareDataType | awk '/UUID/{print $NF}')";
echo "$udid";

echo "fetching computer record from server...";
response="$(/usr/bin/curl -k -u "${jssUser}:${jssPass}" -H "Accept: application/xml" "${jssURL}/JSSResource/computers/udid/${udid}" -X GET)";
echo "received ${#response}-char response.";

# bail if the response doesn't contain a computer record
if [ ! "$(echo "$response" | grep -c "<id>")" -ge 1 ]; then
	echo "API response abnormal. fatal.";
	problems=99;
	exit 2;
fi

echo -n "checking if Asset Tag of server record is populated: "
assetTag="$( echo "$response" | /usr/bin/awk 'BEGIN{FS="[<>]";RS="/"}; /<asset_tag>/ {print $4}') ";
if [ -z "${assetTag}" ]; then
	# zero length asset tag parsed
	echo -e "empty.\nNothing to do. Exiting.";
	exit ${failIfEmpty};
else
	echo "$assetTag";
fi

sharingName="$assetTag";

# # Currently-disabled sanity check for content of asset tag returned:
#sharingNameOkay="$( echo "${sharingName}" | /usr/bin/grep -c "^[45678]{3,7}[0-9][a-z]\+$" )";
#if [ "$sharingNameOkay" -ne 1 ]; then
#	echo "bad asset tag: ${assetTag}. fatal."
#	exit 4; #bad calculated name 
#else

	sharingName="${prefix}${assetTag}${suffix}";

	echo -n "setting ComputerName: ";
	/usr/sbin/scutil --set ComputerName "${sharingName}" && echo "done" || let problems++;
	echo -n "setting LocalHostName: ";
	/usr/sbin/scutil --set LocalHostName "${sharingName}" && echo "done" || let problems++;
	echo -n "setting HostName: ";
	/usr/sbin/scutil --set HostName "${sharingName}" && echo "done" || let problems++;
	echo "finished. flushing caches and creating success-faux-recept for smart groups";
	dscacheutil -flushcache
	if [ "$problems" -eq 0 ]; then
		echo "encountered $problems problems. creating fake receipt."
		touch /Library/Application\ Support/JAMF/Receipts/2016-01-01_Script_AssetTagToComputerName_Done.dmg 
	else
		echo "encountered $problems problems, not creating success recept; process failed."
		exit 99; # non-zero problem count
	fi
#fi

echo "done"
exit 0;
