#!/usr/bin/bash

#Comunidad autonoma de Catalunya

baseprog=$(dirname $0)
wikiprovincias="$(mktemp)"".html"
wikicomarcas="$(mktemp)"".html"
wikimunicipios="$(mktemp)"".html"
wikipedia=""
tmphtml="$(mktemp)"".html"
fecha=$(date +"%d/%m/%Y")
basepath=$(pwd)"/../catalunya.redama.es"
uid=$(id -u)
userna=$(id -nu $uid)
groupna=$(getent group "${userna}" | cut -d : -f1)
tmpcomarcas=$(mktemp)
comarca=""

COMPOSITE=/usr/bin/composite
CONVERT=/usr/bin/convert


sanitizer () {
	for filename in *; do
		if [[ $(echo "${filename}") | grep -c "\(1\)" ]]; then
			rm -rf "${filename}"
		else
			newfilename=$(echo "${filename}" | sed 's|"||g' | sed "s|'|e_|g" | sed 's| ||g' | sed 's|Escut|Escudo|g' | sed 's|COA_of_|Escudo_de_|g' \
				| sed -e 's|[Cc]oa[t|ts]_of_[Aa]rms_of_|Escudo_de_|g' | sed -e 's|[àÀ]|a|g' -e 's|[èÈ]|e|g' -e 's|[ìÌ]|i|g' -e 's|[òÒ]|o|g' -e 's|[ùÙ]|u|g' -e 's|[áÁ]|a|g' -e 's|[éÉ]|e|g' -e 's|[íÍ]|i|g' -e 's|[óÓ]|o|g' -e 's|[úÚ]|u|g' -e 's|[çÇ]|c|g' \
				| sed 's|-|_|g' | sed 's|Blaso|Escudo|g' | sed 's|_heraldic||g' | sed 's|_[Oo]ficial||g' | sed 's|Logo|Escudo_de|g' | sed 's|Bandera|Escudo_de|g' | sed -e 's|(.*)||g' | sed 's|_\.|.|g' | sed 's|,||g' | sed 's|le_||' | sed 's|les_||' \
				| sed 's|Escudo_des|Escudo_de|' | sed 's|Escudo_del|Escudo_de|' | sed 's|de_Le|de_le|' | sed 's|de_La|de_la|' | sed 's|Sa|sa|')
			mv "${filename}" "Sanitized/""${newfilename}"
		fi
	done
}

mark () {
	ls -1 Sanitized/* | awk -F\/ '{print "composite -compose multiply -gravity SouthWest watermark/watermark.jpg Sanitized/"$(NF)" Watermarked/"$(NF)".jpg"}' | sh
	ls -1 Watermarked/* | awk -F\/ '{print "composite -compose multiply -gravity SouthEast watermark/watermark2.jpg Watermarked/"$(NF)" /tmp/"$(NF)" && mv /tmp/"$(NF)" Watermarked/"}' | sh
	ls -1 Watermarked/* | awk -F\/ '{print "convert -resize 400 Watermarked/"$(NF)" /tmp/"$(NF)" && mv /tmp/"$(NF)" Watermarked/"}' | sh

}

varsanitizer () {
	name=$(echo "${1}" | sed -e 's|[àÀ]|a|g' -e 's|[èÈ]|e|g' -e 's|[ìÌ]|i|g' -e 's|[òÒ]|o|g' -e 's|[ùÙ]|u|g' -e 's|[áÁ]|a|g' -e 's|[éÉ]|e|g' -e 's|[íÍ]|i|g' -e 's|[óÓ]|o|g' -e 's|[úÚ]|u|g' -e 's|[çÇ]|c|g' -e 's| |_|g' -e "s|'|_|g" )
	echo "${name}"
}

read -p "Quieres añadir páginas sobre las provincias catalanas? 1/0 " ctrl
[ $ctrl = 1 ] && \
	read -p "Escribe la provincia de añadir a tu web, la primera letra MAIUSC " provincia && \
	provincia_limpia=$(varsanitizer "${provincia}") && \
	wget -O "${wikiprovincias}" https://es.wikipedia.org/wiki/Anexo:Provincias_y_ciudades_aut%C3%B3nomas_de_Espa%C3%B1a && \
	gawk -i inplace '/wikitable/,/\/table/' "${wikiprovincias}" && \
	if [ ! -d "${basepath}/Provincias/${provincia_limpia}" ]; then
		mkdir "${basepath}/Provincias/${provincia_limpia}"
	fi && \
	install -o "${userna}" -g "${groupna}" -m 0640 Provincias/header.html  "${basepath}/Provincias/${provincia_limpia}/header.html" && \
	install -o "${userna}" -g "${groupna}" -m 0640 Provincias/article.html  "${basepath}/Provincias/${provincia_limpia}/article.html" && \
	install -o "${userna}" -g "${groupna}" -m 0640 Provincias/footer.html  "${basepath}/Provincias/${provincia_limpia}/footer.html" && \
	sed -i "s|/PROVINCIA/|${provincia}|g"  "${basepath}/Provincias/${provincia_limpia}/header.html" && \
	sed -i "s|/PROVINCIA/|${provincia}|g"  "${basepath}/Provincias/${provincia_limpia}/article.html" && \
	sed -i "s|/PROVINCIA/|${provincia}|g"  "${basepath}/Provincias/${provincia_limpia}/footer.html" && \
	sed -i "s|/FECHA/|${fecha}|g"  "${basepath}/Provincias/${provincia_limpia}/footer.html" && \
	sed -i "s|/ESCUDOPROVINCIA/|Escudo_de_la_provincia_de_${provincia_limpia}.jpg|" "${basepath}/Provincias/${provincia_limpia}/article.html" && \
	uri="https://es.wikipedia.org""$(cat "${wikiprovincias}" | grep "${provincia}" | grep title | head -n 1 |  grep -o '".*"' | cut -d ' ' -f1 | sed 's|"||g')" && \
	wget -O "${wikicomarcas}" "${uri}" && \
	cat "${wikicomarcas}" | awk "/<b>${provincia}/,/<\/p>/" > "${tmphtml}" && \
	wikipedia=$(lynx --dump "${tmphtml}" |  awk -v RS= 'NR==1'| sed -e 's|\]|\] |g' |  sed "s|\[[0-9]\]||g" |  sed "s|\[[0-9][0-9]\]||g" | sed "s|\^||g" | sed "s|&*&||g") && \
	awk '1;/\/WIKIPEDIA\//{exit}' "${basepath}/Provincias/${provincia_limpia}/article.html" | awk 'NR>2 {print last} {last=$0}' > "${tmphtml}" && \
	echo "${wikipedia}" >> "${tmphtml}" && \
	sed -n '/\/WIKIPEDIA\//,$p' "${basepath}/Provincias/${provincia_limpia}/article.html" | sed '1d' >> "${tmphtml}" && \
	cat "${tmphtml}" > "${basepath}/Provincias/${provincia_limpia}/article.html" && \
	lynx --dump "${wikicomarcas}" | awk '/Comarcas\[/{t=1}; t==1{print; if (/Eco/ || /Demo/ || /Part/){c++}}; c==1{exit}' | sed -e '1d' -e '$d' | sed -e '1d' -e '$d' | cut -d ] -f2 > "${tmpcomarcas}" && \
	while read -r line
	do 
		[ "${line}" ] && \
			comarcalimpia=$(echo $(varsanitizer "${line}") | sed "s|(.*)||g" | sed "s|_$||") && \
			wget -O "/tmp/${comarcalimpia}.html" "https://es.wikipedia.org/wiki/${comarcalimpia}" && \
			coord=$(lynx --dump /tmp/${comarcalimpia}.html | grep Coord | awk 'FNR == 2' | cut -d ] -f3 | cut -d \/ -f1) && \
			pobla=$(lynx --dump /tmp/${comarcalimpia}.html | awk 'f{print;f=0} /Pobla/{f=1}' | head -n 1 | sed "s|(.*)||" | sed "s|^.*\(Total.*$\)|\1|") && \
			comarca="${comarca}"$(printf '\t\t%s\n' "<tr><td>${coord}</td>") && \
			comarca="${comarca}"$(printf '\t\t\t%s\n' "<td><a href=\"/Comarcas/${comarcalimpia}/index.html\" title=\"Redama internet rural ilimitado comarca de ${line}\">${line}</a></td>") && \
			comarca="${comarca}"$(printf '\t\t%s\n' "<td>${pobla}</td></tr>")  || \
			break 
	done <"${tmpcomarcas}" && \
	sed -i "s|/COMARCA/|${comarca}|" "${basepath}/Provincias/${provincia_limpia}/article.html" && \ 
	cat "${basepath}/Provincias/${provincia_limpia}/header.html" > "${basepath}/Provincias/${provincia_limpia}/index.html" && \
	cat "${basepath}/Provincias/${provincia_limpia}/article.html" >> "${basepath}/Provincias/${provincia_limpia}/index.html" && \
	cat "${basepath}/Provincias/${provincia_limpia}/footer.html" >> "${basepath}/Provincias/${provincia_limpia}/index.html"
read -p "Quieres sanear la carpeta de los escudos de municipios? 1/0 " ctrl
[ $ctrl = 1 ] && \
	cd "Img/" && \
	sanitizer
cd $baseprog
read -p "Quieres aplicar filigrana a todas las imagenes? 1/0 " ctrl
[ $ctrl = 1 ] && \
	cd "Img/" && \
	mark && \
	cd "Watermarked/" && \
	for file in *; do  name=$(echo $file | cut -d . -f1); mv ${file} ${name}".jpg"; done
cd $baseprog

