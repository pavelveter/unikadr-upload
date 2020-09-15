#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo -e "\nUnikadr Folder Renamer\n"

dir_num=`ls -1 | grep EOS5D | wc -l | tr -d ' '`
class_names_num=0


while [[ ! ${class_names_num} == ${dir_num} ]]; do
    echo Enter ${dir_num} class names, separated by space: 
    read class_names
    class_names_num=`echo ${class_names} | wc -w | tr -d ' '`
    
    [[ ! ${class_names_num} == ${dir_num} ]] && echo -e "\e[31mThe number of class names does not match the number of folders in the current directory\n\e[0m"
done


echo -e "\n\e[92mWe are ready to make this renaming:\e[0m"
i=1
for f in *EOS5D; do
    if [[ -d ${f} ]]; then
        echo $f ---\> `echo ${class_names} | cut -d " " -f ${i}`
        let i+=1
    fi
done

echo -e " \e[92m"
read -p "Press ENTER to rename"

i=1
for f in *EOS5D; do
    if [[ -d ${f} ]]; then
        mv "${f}" "`echo ${class_names} | cut -d " " -f ${i}`"
        let i+=1
    fi
done

rm -rf MISC

echo -e "\e[0m"
ls
