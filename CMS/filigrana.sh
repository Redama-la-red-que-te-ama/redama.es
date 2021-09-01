#!/usr/bin/bash

read -p "Ruta relativa desde raiz del programa de la  imagen? PATH " ruta

filename=$(basename ${ruta})
name=$(basename ${ruta} | cut -d . -f1)
dir=$(echo ${ruta} | sed "s|${filename}||")

printf '%s\n' "composite -compose multiply -gravity SouthWest Img/watermark/watermark.jpg ${ruta} ${dir}${name}.jpg" | sh
printf '%s\n' "composite -compose multiply -gravity SouthEast Img/watermark/watermark2.jpg ${dir}${name}.jpg /tmp/${name}.jpg ; mv /tmp/${name}.jpg ${dir}../Watermarked" | sh
printf '%s\n' "convert -resize 400 ${dir}../Watermarked/${name}.jpg /tmp/${name}.jpg ; mv /tmp/${name}.jpg ${dir}../Watermarked/" | sh

