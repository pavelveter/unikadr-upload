#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# the name of the remote directory for the photographer
readonly photographer=veter
# select prompt view
PS3="#? "

function ErrorExit() {
    echo -e "\e[31mERROR: $1\e[39m"
    say -v Alex Error $1 >/dev/null 2>&1 &
    exit 1
}

function EchoOk {
    echo -e "\e[92mOK: $1\e[39m"
}

function GetRemouteDirs {
    rclone lsd ${yad}${photographer}/$1 | tr -s " " | cut -d " " -f 6
}

echo -e "\nUnikadr --> Yandex.Disk"

# Check for the rclone and the Yandex.Disk config
which rclone > /dev/null || ErrorExit "Can't find rclone. Install it from www.rclone.org."
yad=$(rclone listremotes --long | grep yandex | cut -f 1 -d " ")
[[ -z ${yad} ]] && ErrorExit "Yandex.Disk is not configured. Please run 'rclone config' and set Yandex.Disk up."
# Check for an internet
ping -c 1 disk.yandex.ru > /dev/null || ErrorExit "Can't ping Yandex.Disk. Check internet connection."

schooldirs=`GetRemouteDirs .` || ErrorExit "Can't get remote school directories. Check photographer's path."

echo -e "\nPlease, select the directory of the school"
select school in ${schooldirs}; do
    if [[ -z ${school} ]]; then
        echo "You entered the wrong number, please, try again"
    else
        echo -e " "
        EchoOk "The directory of the school is '${school}'"
        break
    fi
done

classesdirs=`GetRemouteDirs ${school}` || ErrorExit "Can't get classes."

# Print the remote directories for the classes
echo -e "\nThe next class folders were found on Yandex.Disk\n(those in the current local directory are highlighted):\n"
i=0

for class in ${classesdirs}; do
    let i+=1;

    if [[ -d ${class:0: -1} ]]; then
        echo -ne "\e[1m${class}\e[0m  ";
    else
        echo -ne "\e[90m${class}\e[0m  "
    fi

    [[ ${#class} < 4 ]] && echo -n " "
    [[ $((i % 9)) == 0 ]] && echo -en "\n"
done

# Get background names from Yandex.Disk
anyclass=`echo ${classesdirs} | cut -d " " -f1`
backgrounddirs=`GetRemouteDirs ${school}/${anyclass}` || ErrorExit "Can't get backround directories."

echo -e "\nSelect the type of the backgroud"

select background in ${backgrounddirs}; do
    if [[ -z ${background} ]]; then
        echo "You entered the wrong number, please, try again"
    else
        echo -e " "
        EchoOk "You selected the background, named '${background}'"
        break
    fi
done

# Check the class directories at Yandex.Disk
errordirs=""
okdirs=""

for f in *; do
    if [[ -d ${f} ]]; then
        rclone lsd ${yad}${photographer}/${school}/${f}-/${background}/. > /dev/null 2>&1 \
            && okdirs+=${f}" " \
            || errordirs+=${f}" ";
    fi
done

if [[ ! -z ${errordirs} ]]; then
    echo -e "\e[31m"

    for f in ${errordirs}; do
        echo Can\'t find path ${yad}${photographer}/${school}/${f}-/${background} at Yandex.Disk.
    done

    ErrorExit "Please, check directories, listed above at Yandex.Disk"
fi

for f in ${okdirs}; do
    echo ${f} --\> ${yad}${photographer}/${school}/${f}-/${background}
done

echo -e "\e[92m"
read -p "Press ENTER to start syncing"
echo -e "\e[39m"

# Delete CR2 files marked with the Photomechanic Magenta flag (button 1) based on XMP files
for f in *; do
    if [[ -d ${f} ]]; then
        for fn in ${f}/*.XMP; do
            grep 'photomechanic:ColorClass=\"1\"' ${fn} > /dev/null \
                && rm ${fn%.*}.CR2;
        done
    fi
done

# Clean some temporary files
find . -name ".DS_Store" -delete
find . -name "*.XMP" -delete

errordirs=""
okdirs=""

[[ -f rclone.lock ]] && ErrorExit "'rclone.lock' found. Probably we are access Yandex.Disk right now."

for f in *; do
    if [[ -d ${f} ]]; then
        echo -e "\nSYNC: ${f} --> ${yad}${photographer}/${school}/${f}-/${background}" | tee rclone.lock
        rclone sync $f ${yad}${photographer}/${school}/${f}-/${background} --progress --transfers=20 \
            && okdirs+=${f}" " \
            || errordirs+=${f}" ";
    fi
done

rm rclone.lock

echo -e " "

if [[ ! -z ${okdirs} ]]; then
    echo -e "\e[92mSynced sucsessfully: "${okdirs}"\e[39m"
fi

if [[ ! -z ${errordirs} ]]; then 
    echo -e "\e[31mProblems have occurred with: "${errordirs}
    ErrorExit "It's sad to report, but there were some errors while syncing the catalogs"
fi

# Renaming
errordirs=""
okdirs=""

[[ -f rclone.lock ]] && ErrorExit "'rclone.lock' found. Probably we are access Yandex.Disk right now."

for f in *; do
    if [[ -d ${f} ]]; then
        echo -e "RENAME: ${yad}${photographer}/${school}/${f}- --> ${yad}${photographer}/${school}/${f}" | tee rclone.lock
        rclone moveto ${yad}${photographer}/${school}/${f}- \
                      ${yad}${photographer}/${school}/${f} --progress > /dev/null 2>&1 \
            && okdirs+=${f}" " \
            || errordirs+=${f}" ";
    fi
done

rm rclone.lock

echo -e " "

if [[ ! -z ${okdirs} ]]; then
    echo -e "\e[92mRenamed sucsessfully: "${okdirs}"\e[39m"
fi

if [[ ! -z ${errordirs} ]]; then 
    echo -e "\e[31mProblems have occurred with: "${errordirs}
    ErrorExit "Bad news, but there were some issues while renaming the folders"
fi

echo " "
say -v Samantha Renaming is complete. >/dev/null 2>&1 &
echo -e "That's all folks. Scripted by instagram.com/pavelveter\n"
