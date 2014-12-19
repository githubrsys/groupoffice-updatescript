#!/bin/bash

# ---------------------------------------------------------------------------
# goupdate.sh - sophisticated update & backup of GroupOffice

# Copyright 2014, r-system GmbH - D.Rosier <support@r-system.de>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at <http://www.gnu.org/licenses/> for
# more details.

# Purpose: Update existing Group-Office 6.1.x Version with automatic download of latest version, optional backup function, including a mysql dump and automatic zPush installation.

# Usage: Set constants in this file, then run it.
# Usage: This file must be run in present shell. So make it executable with chmod +x goupdate.sh and start with ./goupdate.sh. Calling by sh goupdate.sh will fail.

# Revision history:
# 2014-11-11  Created initial Verision
# ---------------------------------------------------------------------------


####
#### Set the constants
####


# Show changelog after successful update permanently?
showChangelog="0";

# Is this a licensed version?
updateLicensedVersion="0";

# Path where this script resides
localfolder="";

# Where is your GroupOffice installation located
installfolder="${localfolder}/group-office";

# Temporary Data; normally this can be left as it is
tempfolder="${localfolder}/.GroupOffice_update";

# Where shall backups go; normally this can be left as it is
backupFolder="${localfolder}/.gobackup"; 

# Shall zPush get installed?
enableZpushInstall="0";

# Which zPush Version?
zPushVersion="2.1.3-1892";

# Automatic backup your GO installation before update?
enableBackup="0";

# Shall update run instantly or do you want to get asked for processing
askForUpdate="1";                                    


####
#### Set the constants end
####












###### 
###### Do not touch below unless you know what you are doing!
######



























if [ "${localfolder}" = "" ]; then localfolder=`pwd`; echo -e "localfolder is set to ${localfolder}"; fi
GOURL="http://sourceforge.net/projects/group-office/files/latest/download?source=typ_redirect";
zPushURL="http://download.z-push.org/final/";
zPushModDir="modules/sync/z-push21";
zPushFolder=`echo $zPushVersion | cut -c 1-3`;
zPushFolderLocal=`echo $zPushFolder | sed -e 's/\.//g'`;
licenseFilename="GroupOffice-pro-6.1-license.txt";
NOW=$(date +"%d-%m-%Y_%H%M%S")

cd `dirname "$0"`

gofilename=$(curl -sIL ${GOURL} | grep -o -E 'filename=.*$' | sed -e 's/filename=*.//' | sed 's/..$//');
untarFolderName=`echo ${gofilename}| sed -e 's/.tar.gz*.$//'`;

DBcharacterSet="utf8";

function getLatestGO() {
sticky
if [ ! -d "${tempfolder}" ]; then
  mkdir ${tempfolder}
  else
  if [ ! "$dryrun" = "1" ]; then
  echo
  fi
fi

cd ${tempfolder}

echo -e "Downloading ${gofilename} to \n\r\r ${tempfolder}  \033[32;7mPlease wait \033[0m If finished I'll start unpacking files."
if [ ! "$dryrun" = "1" ]; then
curl ${GOURL} -s -O -n -L -J -#
tar xfz ${gofilename}
fi

if [ -d "${tempfolder}/${untarFolderName}" ]; then
#echo -e "\n Unpacking successful. Now I copy important Data to Location."; 

copySettingsAndLicense

else
echo -e "\033[31;7mError:\033[0m Downloaded Data Folder not found. I'll stop here. Bye. \n "; exit 0;
fi
cd ${localfolder}
}

function copySettingsAndLicense() {

	if [ -d "${installfolder}" ]; then
		# echo -e "Installfolder found. Going ahead."; 
	copyfiles=0;
	
	if [ -f "${installfolder}/config.php" ]; then
		echo "copy config";
		cp ${installfolder}/config.php ${tempfolder}/${untarFolderName}/
		((copyfiles++));
		else
		echo -e "\n \033[31;7mError:\033[0m Config file not found. I'll stop here. Bye. \n "; exit 1;
	fi
	
	if [ "$updateLicensedVersion" = 1 ]; then
	
	echo "License is being copied";
	
		if [ -f "${installfolder}/${licenseFilename}" ]; then
			((copyfiles++));
			cp ${installfolder}/${licenseFilename} ${tempfolder}/${untarFolderName}/
			else
			echo -e "\n \033[31;7mError:\033[0m License file not found. I'll stop here. Bye. \n "; exit 1;
		fi
	else
	echo "Community Version is set in Constants";
	fi

	
	if [ "$copyfiles" -gt "0" ]; then
		
			if [ "$enableZpushInstall" = "1" ]; then
			installZpush
			else
			finishing
			fi
		else
		echo -e "\n \033[31;7mError:\033[0m Copyfiles not found. I'll stop here. Bye. \n ";
	fi
	else
	echo -e "\n \033[31;7mError:\033[0m Installation directory not found. Check the constants in this file. I'll stop here. Bye. \n ";
fi
}

function installZpush() {
if [ "$enableZpushInstall" = "1" ]; then
cd `dirname "$0"`
if [ -d "${tempfolder}/${untarFolderName}/${zPushModDir}" ]; then
cd ${tempfolder}/${untarFolderName}/${zPushModDir}/
if [ ! "$dryrun" = "1" ]; then
rm -f z-push-$zPushVersion.tar.gz
rm -Rf ../../z-push*
echo -e "\n Installing zPush"; 
curl ${zPushURL}/${zPushFolder}/z-push-$zPushVersion.tar.gz -s -O -L -J -#

tar zxf z-push-$zPushVersion.tar.gz
mv z-push-$zPushVersion ../../z-push${zPushFolderLocal}

cp -R backend/go ../../z-push${zPushFolderLocal}/backend
cp config.php ../../z-push${zPushFolderLocal}

rm -f z-push-$zPushVersion.tar.gz
fi
echo -e "z-push_${zPushVersion} installed! \n ";
else
echo -e "\n \033[31;7mError:\033[0m zPush directory in ${tempfolder}/${untarFolderName}/${zPushModDir} not found. I'll stop here. Bye. \n ";
fi
	  
	  
	  
finishing
else
echo -e "\n No zPush Selected \n ";
fi
}
function activateCopy(){
rm -Rf ${installfolder}_*
mv ${installfolder} ${installfolder}_${NOW}
mv ${tempfolder}/${untarFolderName} ${installfolder}
}

function showlog(){
echo "************************************";
head -n 35 ${installfolder}/CHANGELOG.TXT;
echo "************************************";
echo -e "\033[32;7mInstallation successful \033[0m \nNow open GroupOffice in your Browser.\n";
}
function finishing(){
fullBackup
activateCopy

if [ -f "${installfolder}/CHANGELOG.TXT" ]; then

if [ "$showChangelog" = "1" ]; then
showlog 
else
read -n1 -t 7 -p "Show changelog this time? (y/n) "
echo 
[[ $REPLY = [yY] ]] && showlog || { echo -e "\033[32;7mInstallation successful \033[0m \nNow open GroupOffice in your Browser."; exit 1; } 

echo -e "\033[32;7mInstallation successful \033[0m \nNow open GroupOffice in your Browser.\n"; 
fi
else
echo -e "\n \033[31;7mError:\033[0m Changelog not found something is wrong. I'll stop here. Bye. \n ";
fi
}

movebackup(){
#echo -e "\n\r Moving backup to backup directory.";
	if [ ! -d ${backupFolder} ]; then
	mkdir ${backupFolder} && mv *.tar.gz ${backupFolder}/
	else
	mv *.tar.gz ${backupFolder}/
	fi
	cd ${backupFolder}
	echo -e "\n\r Files in Backup directory:";
	for file in *.tar.gz
    	do
    		if [ -f "$file" ];then
    			echo "$file" 
    		else
    			echo -e "\n\r No tar.gz Files in Backup directory \n\n";
    		fi
    	done
    	echo -e "\n\r";
    	cd ${localfolder}
}

getDBData() {
if [ -e ${installfolder}/config.php ]; then 
#echo -e "\n\r\r Reading file ${installfolder}/config.php";
	database=`awk -F "=" '/db_name/ {++c;if(c%2==1)print $2}' ${installfolder}/config.php | sed -e 's/^.//' -e 's/..$//' | head -n1`
	username=`awk -F "=" '/db_user/ {++c;if(c%2==1)print $2}' ${installfolder}/config.php  | sed -e 's/^.//' -e 's/..$//'| head -n1`
	password=`awk -F "=" '/db_pass/ {++c;if(c%2==1)print $2}' ${installfolder}/config.php  | sed -e 's/^.//' -e 's/..$//'| head -n1`
    host=`awk -F "=" '/db_host/ {++c;if(c%2==1)print $2}' ${installfolder}/config.php  | sed -e 's/^.//' -e 's/..$//'| tail -n1`
	datenow=$(date +"%d-%m-%Y_%H%M%S")
	#echo -e "\n\r\r Database: ${database} \n\n Character: ${DBcharacterSet} \n\n Pass: ${password} \n\n Host: ${host}  ";
	return
	else
	echo -e "\n\r\r Config File not found";
	fi
}

makedump() {
    getDBData
    # echo -e "\n\r Doing Autorepair for DB ${database} on Host ${host}";
    mysqlcheck ${database} -u${username} -p${password} -h${host} -s --force --auto-repair
   # echo -e "\n\r Autorepair Done";
	SQL="go_${database}_utf8_${datenow}.sql"
	# echo -e "\n\r Creating ${DBcharacterSet} Dump ${DBHOST} $SQL in $(pwd)";
	mysqldump --default-character-set=${DBcharacterSet} -u${username} -p${password} -h${host} ${database} > ${installfolder}/${SQL}
	# echo -e "\n\r Dump of Database ${database} Done.";
}


function fullBackup() {
if [ "$enableBackup" = "1" ]; then
    cd ${installfolder}
	#echo -e "Copy Database"; 
	makedump
	# echo -e "\n Copy Done."; 
	echo -e "\n Now packing Dump and ${installfolder}";
	cp .htaccess _.htaccess 2>/dev/null;
	#echo -e "\n htaccess files in backup renamed to _.htaccess"; 
	tar -czf go_complete_backup_${NOW}.tar.gz  *
	#echo -e "\n Backup Done."; 
	
	if [ ! -e go_complete_backup_*.tar.gz ]; then 
	echo "no backup present in folder. Seems  that something went wrong. I´ll stop here and do not remove any files."
	exit 0;
	else
	rm _.htaccess 2> /dev/null 
	movebackup
	fi
	else
	cd ${installfolder}
	makedump
	echo -e "Skipping backup due disabled in constants. A versioned copy with a dump of the old production environment is created nontheless and will be deleted on next run of this script.\n"
	fi
}

function sticky() {
clear
echo -e " \n\n \033[34;7m Welcome to the Group Office Update script. ©r-system GmbH \033[0m \n\n"
}


function checkDepedencies() {
deps=0;
if [[ -e '/usr/local/bin/curl' || -e '/bin/curl' || -e '/usr/bin/curl' || -e '/sbin/curl' || -e '/usr/local/sbin/curl' ]]
then
echo -e "curl present";
else
((deps++))
echo -e "\n \033[31;7mError:\033[0m curl not present. Abort."; exit 0;
fi
if [[ -e '/usr/local/bin/awk' || -e '/bin/awk' || -e '/usr/bin/awk' || -e '/sbin/awk' || -e '/usr/local/sbin/awk' ]]
then
echo -e "awk present";
else
((deps++))
echo -e "\n \033[31;7mError:\033[0m awk not present. Abort."; exit 0;
fi
if [[ -e '/usr/local/bin/sed' || -e '/bin/sed' || -e '/usr/bin/sed' || -e '/sbin/sed' || -e '/usr/local/sbin/sed' ]]
then
echo -e "sed present";
else
((deps++))
echo -e "\n \033[31;7mError:\033[0m sed not present. Abort."; exit 0;
fi
if [[ -e '/usr/local/bin/mysql' || -e '/bin/mysql' || -e '/usr/bin/mysql' || -e '/sbin/mysql' || -e '/usr/local/sbin/mysql' ]]
then
echo -e "mysql present";
else
((deps++))
echo -e "mysql not present. Abort."; exit 0;
fi
if [[ -e '/usr/local/bin/mysqladmin' || -e '/bin/mysqladmin' || -e '/usr/bin/mysqladmin' || -e '/sbin/mysqladmin' || -e '/usr/local/sbin/mysqladmin' ]]
then 
echo -e "mysqladmin present";
else
((deps++))
echo -e "\n \033[31;7mError:\033[0m mysqladmin not present. Abort."; exit 0;
fi
if [[ -e '/usr/local/bin/mysqlcheck' || -e '/bin/mysqlcheck' || -e '/usr/bin/mysqlcheck' || -e '/sbin/mysqlcheck' || -e '/usr/local/sbin/mysqlcheck' ]]
then
echo -e "mysqlcheck present";
else
((deps++))
echo -e "\n \033[31;7mError:\033[0m mysql not present. Abort."; exit 0;
fi
if [[ -e '/usr/local/bin/tar' || -e '/bin/tar' || -e '/usr/bin/tar' || -e '/sbin/tar' || -e '/usr/local/sbin/tar' ]]
then
echo -e "tar present";
else
((deps++))
echo -e "\n \033[31;7mError:\033[0m tar not present. Abort."; exit 0;
fi

if [[ -d ${installfolder} ]]; then
echo -e "folders present";
else
((deps++))
echo -e "\n \033[31;7mError:\033[0m Installfolder is not set or cannot be found. Abort."; exit 0;
fi

if [ "$deps" -gt "0" ]; then
echo -e "\n \033[31;7mError:\033[0m Not all dependencies met. Bye. \n ";
else
getLatestGO
fi
}

clear

if [ "$1" = "--write" ]
then
dryrun="0";
sitcky
else
dryrun="0";
sticky
#echo -e " \n\n \033[34;7m.: Dryrun mode. Nothing is deleted or Downloaded. To enable the script run with --write parameter :. \033[0m\n\n Backup is run nontheless if enabled."  
fi 
if [ "$askForUpdate" = "1" ]; then

read -n1 -t 7 -p "Shall update to ${untarFolderName} get started? (y/n) "
echo 
[[ $REPLY = [yY] ]] && checkDepedencies || { echo "OK. Cancel!"; exit 1; } 
else
checkDepedencies
fi



