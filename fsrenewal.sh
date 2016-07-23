#!/bin/bash
# Make sure only root can run this script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

command -v md5sum >/dev/null 2>&1 || { echo >&2 "I require md5sum but it's not installed.  Aborting."; exit 1; }

if [ $# -eq 0 ]
  then
    echo "Enter path that must be renewed"
    exit 1
fi

DIR=$1
cd "$DIR"
CURPATH=`echo ${PWD}`
if [[ "$CURPATH" == '/' || "$CURPATH" == '/etc' || "$CURPATH" == '/lib' ]]; then
  echo "This script must not be used on $CURPATH" 
  exit 1
fi
DIRPATH=`echo ${PWD}`/

# save and change IFS 
OLDIFS=$IFS
IFS=$'\n'

 
# read all directory file name into an array
fileArray=($(find $DIRPATH -type d))
 
# get length of the array
tLen=${#fileArray[@]}
 
# use for loop read all filenames
for (( i=0; i<${tLen}; i++ ));
do
#  echo "Entering directory $DIRPATH${fileArray[$i]}"
echo "Entering directory ${fileArray[$i]}"  
#  cd "$DIRPATH${fileArray[$i]}"
  cd "${fileArray[$i]}"
  TEMP=`echo ${PWD}`/temp_refresh_file/
  mkdir "$TEMP"
  
  # search all files not modified in last 365 days, only in current directory
  for j in `find .  -maxdepth 1 -type f -mtime +365`; do

    # copy file preserving only mode, ownership in temporary place
    cp -a --no-preserve=timestamps "$j" "$TEMP" 

    file1_md5=$(md5sum -q "$j")
    file2_md5=$(md5sum -q "$TEMP$j")

    if [ "${file1_md5}" == "${file2_md5}" ]; then
    
      # remove original copy
      rm "$j"

      #replace it with a newly, fresh copy
      mv $TEMP"$j" .
    else 

      # md5 error, something went wrong, remove only new copy of the file
      rm $TEMP"$j" 
    fi
  done
  rmdir $TEMP
done

# restore IFS
IFS=$OLDIFS
