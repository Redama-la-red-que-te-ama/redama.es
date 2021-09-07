#!/bin/bash

#Comunidad autonoma de Catalunya
#https://github.com/dylanaraps/pure-bash-bible

baseprog=$(pwd)
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
tmpcomarcas2=$(mktemp)
tmpmunicipios=$(mktemp)
comarca=""

cc=($(lynx --dump https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\#Officially_assigned_code_elements | grep '\[[0-9][0-9][0-9][0-9]\][A-Z][A-Z]$' | cut -d \] -f2 | uniq | tr [:upper:] [:lower:]))
duckduckparam=($(curl -sSf https://raw.githubusercontent.com/Redama-la-red-que-te-ama/redama.es/main/CMS/duckduckparams | awk '{print $1}'))


for proxy in $(dig openbsd.telecom.lobby TXT +short | sed 's/\"//g' | tr \; '\n' | sed '$d'); do
	PROXYLOCAL+=("${proxy}"".telecom.lobby:31338")
done
for proxy in $(curl -sSf "https://raw.githubusercontent.com/clarketm/proxy-list/master/proxy-list-raw.txt"); do
		PROXY+=("${proxy}")
done
for proxy in $(lynx --dump https://scrapingant.com/free-proxies/ | awk '/IP/{t=1}; t==1{print; if (/Web/){c++}}; c==1{exit}' | awk 'NF' | awk '{print $1 ":" $2}' | sed '$d' | sed '1d'); do
	PROXY+=("${proxy}")
done

COMPOSITE=/usr/bin/composite
CONVERT=/usr/bin/convert

split() {
   # Usage: split "string" "delimiter"
   IFS=$'\n' read -d "" -ra arr <<< "${1//$2/$'\n'}"
   printf '%s\n' "${arr[@]}"
}

urlencode() {
    # Usage: urlencode "string"
    local LC_ALL=C
    for (( i = 0; i < ${#1}; i++ )); do
        : "${1:i:1}"
        case "$_" in
            [a-zA-Z0-9.~_-])
                printf '%s' "$_"
            ;;

            *)
                printf '%%%02X' "'$_"
            ;;
        esac
    done
    printf '\n'
}

urldecode() {
    # Usage: urldecode "string"
    : "${1//+/ }"
    printf '%b\n' "${_//%/\\x}"
}

ccrand () {
		local rand=$[$RANDOM % ${#cc[@]}]
		echo ${cc[$rand]}
}

duckrand () {
	local rand=$[$RANDOM % ${#duckduckparam[@]}]
	echo ${duckduckparam[$rand]}
}

proxyrand () {
	local rand=$[$RANDOM % ${#PROXY[@]}]
	port=${PROXY[$rand]/${PROXY[$rand]%:*}/}
	[ $(nc -z -v -w1 ${PROXY[$rand]%:*} ${port:1} 2>&1 | grep -c "timed") -eq 0 ] &&  echo "${PROXY[$rand]}" || proxyrand
}

localproxyrand () {
	local rand=$[$RANDOM % ${#PROXYLOCAL[@]}]
	echo ${PROXYLOCAL[$rand]}
}

lynxsanitizer () {
	while read -r data; do
		 printf "%s\n" "$data" | grep -v 'Bandera\|Escudo\|Comú\|Área\|Municipio\|Localitz\|PSC\|ERC\|CUP\|CiU\|[gG]rup\|Junts\|JxC\|Xavier\|Marta\|Tot\ per\|Decidim\|Ignasi\|Podem\|Alternativa\|Assemblea\|Laura\|Carlos\|Jordi\|Superficie\|PPC\|ICV\|Ciudad'
	done
  #echo "${asdf}" | grep -v 'Bandera\|Escudo\|Comú\|Área\|Municipio\|Localitz\|PSC\|ERC\|CUP\|CiU\|[gG]rup\|Junts\|JxC\|Xavier\|Marta\|Tot\ per\|Decidim\|Ignasi\|Podem\|Alternativa\|Assemblea'
}

urisearch () {
	declare -i counter=$6
	let counter+=1

	if [ `expr $counter % 2` == 0 ]; then
		proxy=$(localproxyrand)
		prog="/usr/bin/ddgr"
		opt="-r `duckrand`"
	else
		proxy=$(localproxyrand)
		prog="/usr/bin/ddgr"
		opt="-r `duckrand`"
	fi
	if [ $counter == 6 ]; then
		proxy=$(proxyrand)
		prog="/usr/bin/googler"
		opt="-g `ccrand`"
	elif [ $counter == 12 ]; then
		proxy=$(localproxyrand)
		prog="/usr/bin/googler"
		opt="-g `ccrand`"
		let counter=0
	fi

	uri=$(timeout 2 ${prog} -w es.wikipedia.org --proxy ${proxy} -n4 --np --json ${opt} -x "${1}" "${2}" "${3}" "${4}" "${5}" 2>&1)
	[[ "${uri}" ]] && [[ "${uri}" != \[ERROR\]* ]] && \
		url=$(echo "${uri}" | grep url | grep -v '[Aa]nexo\|[Cc]omarca\|[Pp]ortada\|[Pp]ueblos\|[Cc]ategor\|'"${3}"'' | cut -d \" -f4 | awk 'FNR == 1') && \
		[[ "${url}" ]] && [ $(curl -s --head "${url}" | head -n 1 | awk '{print $2}') -ne 404 ] && \
			echo "${url}" \
		|| \
		eval "urisearch" $(shuf -i 1-2 | paste - -s -d ' ' | sed "s|\([0-9]\)|\"\$\{\1\}\"|g") "${3}" $(shuf -i 4-5 | paste - -s -d ' ' | sed "s|\([0-9]\)|\"\$\{\1\}\"|g") "${counter}"
}

sanitizer () {
	for filename in $(find "${1}" -maxdepth 1 -type f); do
		newfilename=$(echo "${filename}" | sed "s|${1}/||" | sed 's|"||g' | sed "s|'|e_|g" | sed 's| ||g' | sed 's|Escut|Escudo|g' | sed 's|COA_of_|Escudo_de_|g' \
		| sed -e 's|[Cc]oa[t|ts]_of_[Aa]rms_of_|Escudo_de_|g' | sed -e 's|[àÀ]|a|g' -e 's|[èÈ]|e|g' -e 's|[ìÌ]|i|g' -e 's|[òÒ]|o|g' -e 's|[ùÙ]|u|g' -e 's|[áÁ]|a|g' -e 's|[éÉ]|e|g' -e 's|[íÍ]|i|g' -e 's|[óÓ]|o|g' -e 's|[úÚ]|u|g' -e 's|[çÇ]|c|g' \
		| sed 's|-|_|g' | sed 's|Blaso|Escudo|g' | sed 's|_heraldic||g' | sed 's|_[Oo]ficial||g' | sed 's|Logo|Escudo_de|g' | sed 's|Bandera|Escudo_de|g' | sed -e 's|(.*)||g' | sed 's|_\.|.|g' | sed 's|,||g' | sed 's|le_||' | sed 's|les_||' \
		| sed 's|Escudo_des|Escudo_de|' | sed 's|Escudo_del|Escudo_de|' | sed 's|de_Le|de_le|' | sed 's|de_La|de_la|' | sed 's|Sa|sa|' | sed 's|Localitzacio|Mapa|')
		cp "${filename}" "${1}/../Sanitized/${newfilename}"
	done
}



mark () {
	case "${2}" in
		"provincias")
			for file in $(find "${1}/Sanitized/" -maxdepth 1 -type f); do
				filename=$(echo "${file}" | sed "s|${1}/Sanitized/||")
				name=$(echo $filename | cut -d . -f1)
				printf '%s\n' "composite -compose multiply -gravity SouthWest Img/watermark/watermark.jpg Img/Provincias/Sanitized/${filename} Img/Provincias/Watermarked/${name}.jpg" | sh
				printf '%s\n' "composite -compose multiply -gravity SouthEast Img/watermark/watermark2.jpg Img/Provincias/Watermarked/${name}.jpg /tmp/${name}.jpg ; mv /tmp/${name}.jpg Img/Provincias/Watermarked/" | sh
				printf '%s\n' "convert -resize 400 Img/Provincias/Watermarked/${name}.jpg /tmp/${name}.jpg ; mv /tmp/${name}.jpg Img/Provincias/Watermarked/" | sh

			done
		;;
		"comarcas")
			for file in $(find "${1}/Sanitized/" -maxdepth 1 -type f); do
				filename=$(echo "${file}" | sed "s|${1}/Sanitized/||")
				name=$(echo $filename | cut -d . -f1)
				printf '%s\n' "composite -compose multiply -gravity SouthWest Img/watermark/watermark.jpg Img/Comarcas/Sanitized/${filename} Img/Comarcas/Watermarked/${name}.jpg" | sh
				printf '%s\n' "composite -compose multiply -gravity SouthEast Img/watermark/watermark2.jpg Img/Comarcas/Watermarked/${name}.jpg /tmp/${name}.jpg ; mv /tmp/${name}.jpg Img/Comarcas/Watermarked/" | sh
				printf '%s\n' "convert -resize 400 Img/Comarcas/Watermarked/${name}.jpg /tmp/${name}.jpg ; mv /tmp/${name}.jpg Img/Comarcas/Watermarked/" | sh
			done
		;;
	esac
}

varsanitizer () {
	case "${2}" in
		"left")
			name=$(echo "${1}" | sed -e 's|[àÀ]|a|g' -e 's|[èÈ]|e|g' -e 's|[ìÌ]|i|g' -e 's|[òÒ]|o|g' -e 's|[ùÙ]|u|g' -e 's|[áÁ]|a|g' -e 's|[éÉ]|e|g' -e 's|[íÍ]|i|g' -e 's|[óÓ]|o|g' -e 's|[úÚ]|u|g' -e 's|[çÇ]|c|g' -e 's| |_|g' \
				-e "s|'|_|g" -e "s|_$||g" -e "s|_.$||g")
		;;
		"right")
			name=$(echo "${1}" | sed -e 's|_| |g' -e "s|%27|'|g" | sed "s|(.*)||g" )
		;;
	esac
	echo "${name}"
}

urisanitizer () {
	case "${2}" in
		"left")
		name=$(echo "${1}" | sed -e "s|á|%C3%A1|g" -e "s|à|%C3%A0|g" -e "s|é|%C3%A9|g" -e "s|è|%C3%A8|g"   -e "s|í|%C3%AD|g" -e "s|ó|%C3%B3|g" -e "s|ò|%C3%B2|g" -e "s|ú|%C3%BA|g" -e "s|ü|%C3%BC|g" -e "s|ç|%C3%A7|g" -e "s|'|%27|g" \
			-e "s|ñ|%C3%B1|g" -e "s|:|%3A|g" -e "s|/|%2F|g")
		;;
		"right")
		name=$(echo "${1}" | sed -e "s|%C3%A1|á|g" -e "s|%C3%A0|à|g" -e "s|%C3%A9|é|g" -e "s|%C3%A8|è|g"   -e "s|%C3%AD|í|g" -e "s|%C3%B3|ó|g" -e "s|%C3%B2|ò|g" -e "s|%C3%BA|ú|g" -e "s|%C3%BC|ü|g" -e "s|%C3%A7|ç|g" -e "s|%27|'|g" -e "s|%C3%B1|ñ|g" -e "s|%3A|:|g" -e "s|%2F|/|g")
		;;
	esac
	echo "${name}"
}



read -p "Quieres sanear la carpeta de los escudos de provincias? 1/0 " ctrl
[ $ctrl = 1 ] && \
	sanitizer "$(pwd)/Img/Provincias/Raw"
cd $baseprog

read -p "Quieres aplicar filigrana a todas los escudos de provincias? 1/0 " ctrl
[ $ctrl = 1 ] && \
	mark "$(pwd)/Img/Provincias/" "provincias"

cd $baseprog

read -p "Quieres añadir páginas sobre las provincias catalanas? 1/0 " ctrl
[ $ctrl = 1 ] && \
	read -p "Escribe la provincia de añadir a tu web, la primera letra MAIUSC " provincia && \
	provincia_limpia=$(varsanitizer "${provincia}" "left") && \
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
	wikipedia=$(lynx --dump --display_charset=utf-8 "${tmphtml}" |  awk -v RS= 'NR==1'| sed -e 's|\]|\] |g' |  sed "s|\[[0-9]\]||g" |  sed "s|\[[0-9][0-9]\]||g" | sed "s|\^||g" | sed "s|&*&||g") && \
	awk '1;/\/WIKIPEDIA\//{exit}' "${basepath}/Provincias/${provincia_limpia}/article.html" | awk 'NR>2 {print last} {last=$0}' > "${tmphtml}" && \
	echo "${wikipedia}" >> "${tmphtml}" && \
	sed -n '/\/WIKIPEDIA\//,$p' "${basepath}/Provincias/${provincia_limpia}/article.html"  | sed '1d' >> "${tmphtml}" && \
	cat "${tmphtml}" > "${basepath}/Provincias/${provincia_limpia}/article.html" && \
	lynx --dump --display_charset=utf-8 "${wikicomarcas}" | awk '/Comarcas\[/{t=1}; t==1{print; if (/Eco/ || /Demo/ || /Part/){c++}}; c==1{exit}' | grep \* | sed "s|(.*$||" | cut -d ] -f2 > "${tmpcomarcas}" && \
	[ ! -s  $tmpcomarcas ] && \
			lynx --dump --display_charset=utf-8 "${wikicomarcas}" | awk '/Comarcas\[/{t=1}; t==1{print; if (/Eco/ || /Demo/ || /Part/){c++}}; c==1{exit}' | tr ] '\n' | grep '^[A-Z]' | sed "s|\[.*||g" | sed "s|(.*)||g" | sed "s|[,.]||g" | sed "s| y $||g" | sed "s| $||g" | sed '1d' | sed '$d' > "${tmpcomarcas}" &&\
	i=0 ; l=0 &&\
	while read -r line
	do
		if [ "${line}" ]; then
			l=$(expr $l + 1)
			comarcalimpia=$(echo $(varsanitizer "`echo ${line} | sed 's|(.*)||g'`" "left") | sed "s|_$||")
			if [ $(echo ${comarcalimpia} | wc -c) -lt 20 ]; then
				if [ "${comarcalimpia}" = "El_Priorato" ]; then comarcalimpia="Priorato_(Tarragona)"; fi;
				if [ "${comarcalimpia}" = "Urgel" ]; then comarcalimpia="Urgel_(Cataluña)"; fi;
				if [ "${comarcalimpia}" = "Valles" ]; then comarcalimpia="Valles_Oriental" && line="Vallés Oriental"; fi;
				if [ "${comarcalimpia}" = "Noya" ]; then comarcalimpia="Noya_(comarca_de_Cataluña)"; fi;
				if [ "${comarcalimpia}" = "Selva" ]; then comarcalimpia="Selva_(comarca)"; fi;
				if [ "${comarcalimpia}" = "Bergada" ]; then comarcalimpia="Bergadá"; fi;
				wget -O "/tmp/${comarcalimpia}.html" "https://es.wikipedia.org/wiki/${comarcalimpia}"
				coord=$(lynx --dump --display_charset=utf-8 /tmp/${comarcalimpia}.html | grep Coord | awk 'FNR == 2' | cut -d ] -f3 | cut -d \/ -f1)
				if [ $(echo $coord | head -c 1) != 4 ]; then
					coord=$(lynx --dump --display_charset=utf-8 /tmp/${comarcalimpia}.html | grep Coord | awk 'FNR == 1' | cut -d ] -f3 | cut -d \/ -f1)
				fi
				pobla=$(lynx --dump --display_charset=utf-8 /tmp/${comarcalimpia}.html | awk 'f{print;f=0} /Pobla/{f=1}' | head -n 1 | sed "s|(.*)||" | sed "s|^.*\(Total.*$\)|\1|")
				if [ "${comarcalimpia}" = "Valle_de_Aran" ]; then pobla="Total	9971 hab."; fi
				comarca="${comarca}"$(printf '\t\t%s\n' "<td>${coord}</td>")
				comarca="${comarca}"$(printf '\t\t\t%s\n' "<td><a href=\"/Comarcas/${comarcalimpia}/index.html\" title=\"Redama internet rural ilimitado comarca de ${line}\">${line}</a></td>")
				comarca="${comarca}"$(printf '\t\t%s\n' "<td>${pobla}</td>")
			fi
		else
			i=$(expr $i + 1)
			if [ $i -eq 1 ] && [ $l -lt 3 ]; then
				comarca=""
				continue
			 elif [ $i -gt 1 ] && [ $l -ge 3 ]; then
			 	break
		 	fi
	 	fi
	done <"${tmpcomarcas}" && \
	echo $comarca && \
 	sed -i "s|/COMARCA/|${comarca}|" "${basepath}/Provincias/${provincia_limpia}/article.html" && \
 	uri="https%3A%2F%2Fcatalunya.redama.es%2FProvincias%2F${provincia_limpia}%2Findex.html" && \
	sed -i "s|/URI/|${uri}|" "${basepath}/Provincias/${provincia_limpia}/footer.html" && \
	cat "${basepath}/Provincias/${provincia_limpia}/header.html" > "${basepath}/Provincias/${provincia_limpia}/index.html" && \
	cat "${basepath}/Provincias/${provincia_limpia}/article.html" >> "${basepath}/Provincias/${provincia_limpia}/index.html" && \
	cat "${basepath}/Provincias/${provincia_limpia}/footer.html" >> "${basepath}/Provincias/${provincia_limpia}/index.html" && \
	rm -rf "${basepath}/Provincias/${provincia_limpia}/header.html" && \
	rm -rf "${basepath}/Provincias/${provincia_limpia}/article.html" && \
	rm -rf "${basepath}/Provincias/${provincia_limpia}/footer.html"

read -p "Quieres sanear la carpeta de los escudos y banderas de comarcas? 1/0 " ctrl
[ $ctrl = 1 ] && \
	sanitizer "$(pwd)/Img/Comarcas/Raw"
cd $baseprog
read -p "Quieres aplicar filigrana a todos los escudos y banderas de comarcas? 1/0 " ctrl
[ $ctrl = 1 ] && \
	mark "$(pwd)/Img/Comarcas/" "comarcas"
cd $baseprog
for prov in $(find "${basepath}/Provincias/" -type d); do
	provi=$(echo $prov | sed "s|`dirname $prov`/||")
	if [ $(echo $provi | grep -c "Provincias") = 0 ]; then
		read -p "Quieres añadir páginas sobre las comarcas de la provincia de ${provi}? 1/0 " ctrl
		[ $ctrl = 1 ] && \
			lynx --dump --display_charset=utf-8 "http://catalunya.redama.es/Provincias/${provi}/index.html" | awk '/Coor/{t=1}; t==1{print; if (/Internet/){c++}}; c==1{exit}' | grep ] | cut -d ] -f2 | sed 's|Total.*$||g' > "${tmpcomarcas}" && \
			# wget -q "http://catalunya.redama.es/Provincias/${provi}/index.html" -O /tmp/a.html ; cat /tmp/a.html | grep -io '<a href=['"'"'"][^"'"'"']*['"'"'"]' |   sed -e 's/^<a href=["'"'"']//i' -e 's/["'"'"']$//i' | grep Comarcas | sed "s|/| |g" | awk '{print $2}' > "${tmpcomarcas}" &&\
			i=0 ; l=0 &&\
			while read -r line
			do
				comarcalimpia=$(echo $(varsanitizer "`echo ${line} | sed 's|(.*)||g'`" "left") | sed "s|_$||")
				if [ "${comarcalimpia}" = "Valles" ]; then comarcalimpia="Valles_Oriental"; fi;
				if [ "${comarcalimpia}" = "Noya" ]; then comarcalimpia="Noya_(comarca_de_Cataluña)"; fi;
				if [ "${comarcalimpia}" = "Selva" ]; then comarcalimpia="Selva_(comarca)"; fi;
				if [ "${comarcalimpia}" = "El_Priorato" ]; then comarcalimpia="Priorato_(Tarragona)"; fi;
				if [ "${comarcalimpia}" = "Urgel" ]; then comarcalimpia="Urgel_(Cataluña)"; fi;
				if [ "${comarcalimpia}" = "Bergada" ]; then comarcalimpia="Bergadá"; fi;
				[ ! -d "${basepath}/Comarcas/${comarcalimpia}" ] && mkdir "${basepath}/Comarcas/${comarcalimpia}"
				install -o "${userna}" -g "${groupna}" -m 0640 Comarcas/header.html  "${basepath}/Comarcas/${comarcalimpia}/header.html"
				install -o "${userna}" -g "${groupna}" -m 0640 Comarcas/article.html  "${basepath}/Comarcas/${comarcalimpia}/article.html"
				install -o "${userna}" -g "${groupna}" -m 0640 Comarcas/footer.html  "${basepath}/Comarcas/${comarcalimpia}/footer.html"
				sed -i "s|/COMARCA/|${line}|g"  "${basepath}/Comarcas/${comarcalimpia}/header.html"
				sed -i "s|/COMARCA/|${line}|g"  "${basepath}/Comarcas/${comarcalimpia}/article.html"
				sed -i "s|/COMARCA/|${line}|g"  "${basepath}/Comarcas/${comarcalimpia}/footer.html"
				sed -i "s|/FECHA/|${fecha}|g"  "${basepath}/Comarcas/${comarcalimpia}/footer.html"
				uri="https%3A%2F%2Fcatalunya.redama.es%2FComarcas%2F${comarcalimpia}%2Findex.html"
				sed -i "s|/URI/|${uri}|"  "${basepath}/Comarcas/${comarcalimpia}/footer.html"
				a=$(echo "${comarcalimpia}" | wc -c)
				b=$(expr $a / 2)
				c=$(expr $b + 4)
				imgtest=$(echo "${comarcalimpia}" | tail -c $c | head -c 6)
				[ $( echo $imgtest | wc -c ) = 1 ] && imgtest=$(echo "${comarcalimpia}" | head -c 4)
				[ $( echo $imgtest | wc -c ) = 1 ] && imgtest=$(echo "${comarcalimpia}" | tail -c 4)
				escudo=$(ls -1 "${baseprog}/Img/Comarcas/Watermarked/" | grep "${imgtest}" | awk 'FNR == 1')
				if [ "${comarcalimpia}" = "Noya_(comarca_de_Cataluña)" ]; then escudo="Escudo_de_Noya.jpg"; fi;
				if [ "${comarcalimpia}" = "Bergadá" ]; then escudo="Escudo_de_Bergada.jpg"; fi;
				if [ "${comarcalimpia}" = "Selva_(comarca)" ]; then escudo="Mapa_de_la_Selva.jpg"; fi;
				if [ "${comarcalimpia}" = "Priorato_(Tarragona)" ]; then escudo="Escudo_de_Priorato.jpg"; fi;
				sed -i "s|/ESCUDOCOMARCA/|${escudo}|" "${basepath}/Comarcas/${comarcalimpia}/article.html"
				wget -q -O "/tmp/${comarcalimpia}.html" "https://es.wikipedia.org/wiki/${comarcalimpia}"
				cat "/tmp/${comarcalimpia}.html" | sed "s|Bagés|Bages|g" | awk "/<b>${line}/,/<\/p>/" > "${tmphtml}"
				wikipedia=$(lynx --dump --display_charset=utf-8 "${tmphtml}" |  awk -v RS= 'NR==1'| sed -e 's|\]|\] |g' |  sed "s|\[[0-9]\]||g" |  sed "s|\[[0-9][0-9]\]||g" | sed "s|\^||g" | sed "s|&*&||g")
				awk '1;/\/WIKIPEDIA\//{exit}' "${basepath}/Comarcas/${comarcalimpia}/article.html" | awk 'NR>2 {print last} {last=$0}' > "${tmphtml}"
				echo "${wikipedia}" >> "${tmphtml}"
				sed -n '/\/WIKIPEDIA\//,$p' "${basepath}/Comarcas/${comarcalimpia}/article.html"  | sed '1d' >> "${tmphtml}"
				cat "${tmphtml}" > "${basepath}/Comarcas/${comarcalimpia}/article.html"
				wikicomarca="${comarcalimpia}"
				if [ "${comarcalimpia}" = "Alto_Panades" ]; then wikicomarca="Alto_Penedés"; fi;
				if [ "${comarcalimpia}" = "Maresme" ]; then wikicomarca="El_Maresme"; fi;
				lynx --dump --display_charset=utf-8 "https://es.wikipedia.org/wiki/${wikicomarca}" |  grep -v Municipios | awk '/Municipio/{t=1}; t==1{print; if (/Véa/ || /Ref/ || /Hist/ || /Cons/ || /Lug/ || /Demo/ || /TOT/ || /Eco/ || /Veg/ || /Comu/ || /Enla/ || /Geogra/ || /Tercios/ || /Turismo/){c++}}; c==1{exit}' | sed ':a;N;$!ba;s/\n/ /g' | tr '[' '\n' | cut -d ] -f2 | sed "s|(.*$||g" | sed "s|[0-9]*||g" | sed "s|[0-9].*$||g" | sed "s|^ .*$||g" | awk 'NF' | sed "/[)-]/d" |  sed "s|,.*$||g" | sed "s| $||g" | sed "s| .$||g" | sed "/^ .*/d" | sed "s|&*&||g"  | sed 's/  */ /g' | sed '$d' | sed 's/Consejo.*$//g' | lynxsanitizer > "${tmpmunicipios}"
				if [ ! -s  $tmpmunicipios ]; then lynx --dump --display_charset=utf-8 "https://es.wikipedia.org/wiki/${wikicomarca}" |  grep -v Municipios | awk '/Habitantes/{t=1}; t==1{print; if (/Véa/ || /Ref/ || /Hist/ || /Cons/ || /Lug/ || /Demo/){c++}}; c==1{exit}' | sed ':a;N;$!ba;s/\n/ /g' | tr '[' '\n' | cut -d ] -f2 | sed "s|(.*$||g" | sed "s|[0-9]*||g" | awk 'NF' | sed "s|,.*$||g" | sed "s| $||g" | sed "s|&*&||g" | sed "s| .$||g"  | sed 's/  */ /g' | sed '$d' | sed 's/Consejo.*$//g' | lynxsanitizer  > "${tmpmunicipios}"; fi;
				if [ ! -s  $tmpmunicipios ]; then lynx --dump --display_charset=utf-8 "https://es.wikipedia.org/wiki/${wikicomarca}" |  grep -v Municipios | awk '/Ciudad/{t=1}; t==1{print; if (/Véa/ || /Ref/ || /Hist/ || /Cons/ || /Lug/ || /Demo/){c++}}; c==1{exit}' | sed ':a;N;$!ba;s/\n/ /g' | tr '[' '\n' | cut -d ] -f2 | sed "s|(.*$||g" | sed "s|[0-9]*||g" | awk 'NF' | sed "s|,.*$||g" | sed "s| $||g" | sed "s|&*&||g"  | sed "s| .$||g" | sed 's/  */ /g' | sed '$d' | sed 's/Consejo.*$//g' | lynxsanitizer  > "${tmpmunicipios}"; fi;
				if [ ! -s  $tmpmunicipios ]; then lynx --dump --display_charset=utf-8 "https://es.wikipedia.org/wiki/${wikicomarca}" |  grep -v Municipios | awk '/Ciudad/{t=1}; t==1{print; if (/TOT/){c++}}; c==1{exit}' | sed ':a;N;$!ba;s/\n/ /g' | tr '[' '\n' | cut -d ] -f2 | sed "s|[0-9].*$||g" | sed "s|^ .*$||g" | awk 'NF' | sed "/[)-]/d"  | sed '$d' | sed 's/Consejo.*$//g' | lynxsanitizer  > "${tmpmunicipios}"; fi;
				if [ $(wc -l "${tmpmunicipios}" | awk '{print $1}') -eq 1 ]; then lynx --dump --display_charset=utf-8 "https://es.wikipedia.org/wiki/${wikicomarca}" |  grep -v Municipios | awk '/Ciudad/{t=1}; t==1{print; if (/Organización/){c++}}; c==1{exit}' | sed ':a;N;$!ba;s/\n/ /g' | tr '[' '\n' | sed '$d' | tr '[' '\n' | cut -d ] -f2 | sed "s|(.*$||g" | sed "s|[0-9]*||g" | sed "s|,.*$||g" | sed "s| $||g" | sed "s|&*&||g"  | sed "s| .$||g" | sed "s|^ .*$||g" | sed "/)/d" | awk 'NF'  | sed 's/  */ /g' | sed '$d' | sed 's/Consejo.*$//g' | lynxsanitizer > "${tmpmunicipios}"; fi;
				municipio=""
				cat $tmpmunicipios
				while read -r muniline
				do
					if [[ "${muniline}" ]]; then
						municipiolimpio=$(varsanitizer "${muniline}" "left")
						if [ $(echo ${municipiolimpio} | wc -c) -gt 2 ] ; then
							if [[  ! -e "${baseprog}/Municipios/Wikipedia/${municipiolimpio}.html" ]] || [[ ! -s "${baseprog}/Municipios/Wikipedia/${municipiolimpio}.html" ]]; then
								if [ $(curl -s --head "https://es.wikipedia.org/wiki/${municipiolimpio}" | head -n 1 | awk '{print $2}') -ne 404 ] && \
										[ $(curl -s "https://es.wikipedia.org/wiki/${municipiolimpio}" | grep -c "desambiguac") -eq 0 ] && \
										[ $(curl -s "https://es.wikipedia.org/wiki/${municipiolimpio}" | grep -c "tulos\ similares") -eq 0 ]; then
											wget -O "${baseprog}/Municipios/Wikipedia/${municipiolimpio}.html" "https://es.wikipedia.org/wiki/${municipiolimpio}"
								else
									while true; do
										wikiurl=$(urisearch "${muniline}" "municipio" "`urlencode ${wikicomarca}`" "${provi}" "Catalunya" "0")
										municipiolimpio=$(urldecode "$(echo $wikiurl | cut -d / -f5)")
										[[  ! -e "${baseprog}/Municipios/Wikipedia/${municipiolimpio}.html" ]] && wget -O "${baseprog}/Municipios/Wikipedia/${municipiolimpio}.html" "${wikiurl}" ; break
									done
								fi
							fi
						fi
						postal=$(lynx --dump --display_charset=utf-8 "${baseprog}/Municipios/Wikipedia/${municipiolimpio}.html" | grep Código\ postal | awk '{print $3}')
						www=$(lynx --dump --display_charset=utf-8 "${baseprog}/Municipios/Wikipedia/${municipiolimpio}.html" | grep Sitio\ web | awk '{print $3}' | sed "s|\[.*\]||g")
						municipio="${municipio}"$(printf '\t\t%s\n' "<tr><td><strong>${postal}</strong></td>")
						municipio="${municipio}"$(printf '\t\t\t%s\n' "<td><a href=\"/Municipios/${municipiolimpio}/index.html\" title=\"Redama internet rural ilimitado en el municipio de ${muniline}\">${muniline}</a></td>")
						municipio="${municipio}"$(printf '\t\t%s\n' "<td><a href=\"http://${www}\" title=\"Redama internet, WiFi4EU, telefonia y servicios en el municipio de ${muniline}\">${www}</a></td></tr>")
						if [ ! -d "${basepath}/Municipios/${municipiolimpio}" ]; then
							mkdir "${basepath}/Municipios/${municipiolimpio}"
						fi
					fi
				done <"${tmpmunicipios}"
				awk '1;/\/MUNICIPIO\//{exit}' "${basepath}/Comarcas/${comarcalimpia}/article.html" | awk 'NR>2 {print last} {last=$0}' > "${tmphtml}"
				echo "${municipio}" >> "${tmphtml}"
				sed -n '/\/MUNICIPIO\//,$p' "${basepath}/Comarcas/${comarcalimpia}/article.html"  | sed '1d' >> "${tmphtml}"
				cat "${tmphtml}" > "${basepath}/Comarcas/${comarcalimpia}/article.html"
				cat "${basepath}/Comarcas/${comarcalimpia}/header.html" > "${basepath}/Comarcas/${comarcalimpia}/index.html"
				cat "${basepath}/Comarcas/${comarcalimpia}/article.html" >> "${basepath}/Comarcas/${comarcalimpia}/index.html"
				cat "${basepath}/Comarcas/${comarcalimpia}/footer.html" >> "${basepath}/Comarcas/${comarcalimpia}/index.html"
				rm -rf "${basepath}/Comarcas/${comarcalimpia}/header.html"
				rm -rf "${basepath}/Comarcas/${comarcalimpia}/article.html"
				rm -rf "${basepath}/Comarcas/${comarcalimpia}/footer.html"
			done <"${tmpcomarcas}"
	fi
done
