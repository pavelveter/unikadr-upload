#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# the name of the remote directory for the photographer
readonly photographer=/uni-kadr/staff/b/borisov-pavel-vasilevich
# select prompt view
PS3="#? "

function ErrorExit() {
    echo -e "\e[31mERROR: $1\e[39m"
    say -v Alex Error "${1}" >/dev/null 2>&1 &
    exit 1
}

function EchoOk {
    echo -e "\e[92mOK: $1\e[39m"
}

function GetRemouteDirs {
    rclone lsd "${yad}${photographer}/${1}" | tr -s " " | cut -d " " -f 6
}

echo -e "\n\e[34mUnikadr --> Yandex.Disk\e[0m"

# Check for the rclone and the Yandex.Disk config
which rclone > /dev/null || ErrorExit "Can't find rclone. Install it from www.rclone.org."
yad="uk:"
[[ -z ${yad} ]] && ErrorExit "Yandex.Disk is not configured. Please run 'rclone config' and set Yandex.Disk up."
# Check for an internet
ping -c 1 disk.yandex.ru > /dev/null || ErrorExit "Can't ping Yandex.Disk. Check internet connection."

schooldirs=$(GetRemouteDirs .) || ErrorExit "Can't get remote school directories. Check photographer's path."

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

classesdirs=$(GetRemouteDirs "${school}") || ErrorExit "Can't get classes."

# Print the remote directories for the classes
echo -e "\nThe next class folders were found on Yandex.Disk\n(those in the current local directory are highlighted):\n"
i=0

for class in ${classesdirs}; do
    (( i+=1 ))

    if [[ -d ${class:0: -1} ]]; then
        echo -ne "\e[1m${class}\e[0m  ";
    else
        echo -ne "\e[90m${class}\e[0m  "
    fi

    [[ ${#class} -lt 4 ]] && echo -n " "
    [[ $((i % 9)) == 0 ]] && echo -en "\n"
done

# Check the class & background directories at Yandex.Disk
errordirs=""
okdirs=""

for f in *; do
    if [[ -d ${f} ]]; then
        for d in ${f}/*; do
            if [[ -d ${d} ]]; then
                rclone lsd "${yad}${photographer}/${school}/${f}-/$(echo ${d} | grep -o '[^/]*$')/" > /dev/null 2>&1 \
                    && okdirs+="${f}-/$(echo ${d} | grep -o '[^/]*$') " \
                    || errordirs+="${f}-/$(echo ${d} | grep -o '[^/]*$') ";
            fi
        done
    fi
done

if [[ -n ${errordirs} ]]; then
    echo -e "\e[31m"

    for f in ${errordirs}; do
        echo "Can't find path ${yad}${photographer}/${school}/${f}-/$(echo ${d} | grep -o '[^/]*$') at Yandex.Disk."
    done

    ErrorExit "Please, check directories, listed above at Yandex.Disk"
fi

echo -en "\n\e[92mThe next upload will be done:\e[39m\n"
for f in ${okdirs}; do
    echo -e "${f//-/} \e[34m-->\e[0m ${yad}${photographer}/${school}/${f}/"
done

echo -e "\e[92m"
read -rp "Press ENTER to start syncing"
echo -e "\e[39m"

# Clean some temporary files
find . -name ".DS_Store" -delete
find . -name "*.XMP" -delete

errordirs=""
okdirs=""

[[ -f rclone.lock ]] && ErrorExit "'rclone.lock' found. Probably we are access Yandex.Disk right now."

# Turning off VPN
networksetup -disconnectpppoeservice "mac-wg0" && echo -e "\e[34mVPN is turned off\e[0m"

for f in *; do
    if [[ -d ${f} ]]; then

        for d in "${f}"/*; do 
            if [[ -d ${d} ]]; then
                echo -e "\n\e[33mSYNC:\e[0m ${d} \e[34m-->\e[0m ${yad}${photographer}/${school}/${f}-/$(echo ${d} | grep -o '[^/]*$')" | tee rclone.lock

                rclone sync "${d}" "${yad}${photographer}/${school}/${f}-/$(echo ${d} | grep -o '[^/]*$')" --progress --transfers=20 \
                    && okdirs+="${f}-/$(echo ${d} | grep -o '[^/]*$')\n" \
                    || errordirs+="\${f}-/$(echo ${d} | grep -o '[^/]*$')\n";
            fi
        done
    fi
done

# Turning on VPN
networksetup -connectpppoeservice "mac-wg0" && echo -e "\n\e[34mVPN in turned on\e[0m"

rm rclone.lock

echo -e " "

if [[ -n ${okdirs} ]]; then
    echo -e "\e[92mSynced successfully:\n${okdirs//-/}\e[39m"
fi

if [[ -n ${errordirs} ]]; then 
    echo -e "\e[31mProblems have occurred with:\n ${errordirs}"
    ErrorExit "It's sad to report, but there were some errors while syncing the catalogs"
fi

say -v Samantha Renaming is complete. >/dev/null 2>&1 &

echo -e "That's all folks. Scripted by github.com/pavelveter\n"
