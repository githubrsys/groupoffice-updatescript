# GroupOffice update script
 
 This script updates a manually installed GroupOffice instance starting from version 6.1.x to the latest version. 
 If you have installed a repository version you should stick with the repository update process.
  
#### What it does

* Takes care of server prerequisites
* Takes license files into account 
* Optionally makes a versioned backup of the local installation and database dump before update process starts
* Optionally installs z-Push automatically
* Automatic download and installation of latest version from sourceforge
* Versioning of last production folder

## Installation & usage

* Download the file goupdate.sh or get a git copy 
with `git clone https://github.com/githubrsys/groupoffice-updatescript.git` . 

* Copy the file goupdate.sh for best usage to same location where the groupoffice folder resides in filesystem. But not put it into it.
* Open the copied file and set your environment variables in the `Set the constants` section. 
* Then make sure the file is executable by `chmod +x goupdate.sh`. 
* Afterwards run the script with `./goupdate.sh`.
 
#### This file must be run in present shell. Calling by `sh goupdate.sh` can fail.
 
 This script will always produce a copy of your GO installation in actual path with timestamp in foldername. On next update this copyfolder gets removed. This makes it possible to revert to last status if anything has failed. 
 
This script will not determine if the version installed is the same as on sourceforge. It will always update / replace to the version from the remote location.   