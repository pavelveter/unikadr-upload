#!/usr/bin/env bash
#
# Sorting files according to their PictureStyles setting

set -o errexit
set -o nounset
set -o pipefail

readonly ext=CR2

declare -A StyleDirs
StyleDirs=( ["Standard"]="4_green" ["Monochrome"]="4_bw" ["Portrait"]="4_green_wood" )

echo -e "\nUnikadr Sorter\n"
which exiftool > /dev/null || (echo -e "Can't find exiftool. Install it from www.exiftool.org.\n"; exit 1)

for dir in *; do
    # Creating directories
    for newdir in "${StyleDirs[@]}"; do
        [[ ! -d ${dir}/${newdir} ]] && mkdir "${dir}/${newdir}"
    done

    # Do some sorting
    if [[ -d ${dir} ]]; then
        echo "Processing directory ${dir} ($(ls ${dir} | wc -l | xargs) files)" 

        for photo in "${dir}"/*.${ext}; do
            dest=$(dirname ${photo})/"${StyleDirs[$(exiftool -PictureStyle ${photo} | cut -c 35-)]}"
            mv "${photo%.*}.JPG" "${dest}/"
            mv "${photo}" "${dest}/"
        done
    fi
done
