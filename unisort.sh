#!/usr/bin/env bash
#
# В Photomechanic
#  * 2 (красный) — виньетки
#  * 3 (оранжевый) — педагоги

set -o errexit
set -o nounset
set -o pipefail

readonly ext=CR2
readonly ped=ped
readonly all=all

echo -e "\nUnikadr Sorter\n"

currdir=$(pwd | grep -o '[^/]*$')

for dir in *; do
    if [[ -d ${dir} ]]; then

        if ls ${dir}/*.XMP; then

            for fn in ${dir}/*.XMP; do
                cc=$(grep "photomechanic:ColorClass=" ${fn} | cut -d "=" -f 2 | tr -d \");

                # проверяем, не педагог ли это (3 (оранжевый)) в Photomechanic.
                # 4 — групповая
                # Если так — то создаем, если надо папку и перемещаем туда XMP и фотку

                if [[ 4 == ${cc}  ]]; then

                    if [[ ! -d "../${currdir} @" ]]; then
                        echo Need to create directory \"../${currdir} @\"
                        mkdir "../${currdir} @"
                    fi

                    if [[ ! -d "../${currdir} @/${all}" ]]; then
                        echo Need to create directory \"../${currdir} @/${classdir}/${all}\"
                        mkdir "../${currdir} @/${classdir}/${all}";
                    fi

                    echo All ${fn%.*}.${ext} \& ${fn} --\> ${all}
                    mv ${fn} "../${currdir} @/${classdir}/${all}/"
                    mv ${fn%.*}.${ext} "../${currdir} @/${classdir}/${all}/"

                elif [[ 3 == ${cc} ]]; then

                    if [[ ! -d "../${currdir} @" ]]; then
                        echo Need to create directory \"../${currdir} @\"
                        mkdir "../${currdir} @"
                    fi

                    if [[ ! -d "../${currdir} @/${ped}" ]]; then
                        echo Need to create directory \"../${currdir} @/${ped}\"
                        mkdir "../${currdir} @/${ped}";
                    fi

                    echo Teacher ${fn%.*}.${ext} \& ${fn} --\> ${ped}
                    mv ${fn} "../${currdir} @/${ped}/"
                    mv ${fn%.*}.${ext} "../${currdir} @/${ped}/"

                elif [[ 2 == ${cc} ]]; then

                    if [[ ! -d "../${currdir} @" ]]; then
                        echo Need to create directory \"../${currdir} @\"
                        mkdir "../${currdir} @"
                    fi

                    classdir=$(echo ${fn} | cut -d "/" -f 1)

                    if [[ ! -d "../${currdir} @/${classdir}" ]]; then
                        echo Need to create directory \"../${currdir} @/${classdir}\"
                        mkdir "../${currdir} @/${classdir}"
                    fi

                    echo Moving ${fn%.*}.${ext} \& ${fn} --\> \"../${currdir} @/${classdir}\"
                    mv ${fn} "../${currdir} @/${classdir}/"
                    mv ${fn%.*}.${ext} "../${currdir} @/${classdir}/"
                fi
            done
        fi
    fi
done
