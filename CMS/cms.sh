#!/usr/bin/bash

#Comunidad autonoma de Catalunya

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
comarca=""

COMPOSITE=/usr/bin/composite
CONVERT=/usr/bin/convert


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
			name=$(echo "${1}" | sed -e 's|[àÀ]|a|g' -e 's|[èÈ]|e|g' -e 's|[ìÌ]|i|g' -e 's|[òÒ]|o|g' -e 's|[ùÙ]|u|g' -e 's|[áÁ]|a|g' -e 's|[éÉ]|e|g' -e 's|[íÍ]|i|g' -e 's|[óÓ]|o|g' -e 's|[úÚ]|u|g' -e 's|[çÇ]|c|g' -e 's| |_|g' -e "s|'|%27|g" )
		;;
		"right")
			name=$(echo "${1}" | sed -e 's|_| |g' -e "s|%27|'|g" | sed "s|(.*)||g" )
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
	wikipedia=$(lynx --dump "${tmphtml}" |  awk -v RS= 'NR==1'| sed -e 's|\]|\] |g' |  sed "s|\[[0-9]\]||g" |  sed "s|\[[0-9][0-9]\]||g" | sed "s|\^||g" | sed "s|&*&||g") && \
	awk '1;/\/WIKIPEDIA\//{exit}' "${basepath}/Provincias/${provincia_limpia}/article.html" | awk 'NR>2 {print last} {last=$0}' > "${tmphtml}" && \
	echo "${wikipedia}" >> "${tmphtml}" && \
	sed -n '/\/WIKIPEDIA\//,$p' "${basepath}/Provincias/${provincia_limpia}/article.html"  | sed '1d' >> "${tmphtml}" && \
	cat "${tmphtml}" > "${basepath}/Provincias/${provincia_limpia}/article.html" && \
	lynx --dump "${wikicomarcas}" | awk '/Comarcas\[/{t=1}; t==1{print; if (/Eco/ || /Demo/ || /Part/){c++}}; c==1{exit}' | grep \* | sed "s|(.*$||" | cut -d ] -f2 > "${tmpcomarcas}" && \
	if [ -s  $tmpcomarcas ]; then
		i=0 ; l=0 && \
		while read -r line
		do 
			if [ "${line}" ]; then
				l=$(expr $l + 1) 
				comarcalimpia=$(echo $(varsanitizer "`echo ${line} | sed 's|(.*)||g'`" "left") | sed "s|_$||") 
				if [ $(echo ${comarcalimpia} | wc -c) -lt 20 ]; then
					if [ "${comarcalimpia}" = "El_Priorato" ]; then comarcalimpia="Priorato_(Tarragona)"; fi;
					if [ "${comarcalimpia}" = "Urgel" ]; then comarcalimpia="Urgel_(Cataluña)"; fi;
					wget -O "/tmp/${comarcalimpia}.html" "https://es.wikipedia.org/wiki/${comarcalimpia}"
					coord=$(lynx --dump /tmp/${comarcalimpia}.html | grep Coord | awk 'FNR == 2' | cut -d ] -f3 | cut -d \/ -f1) 
					if [ $(echo $coord | head -c 1) != 4 ]; then
						coord=$(lynx --dump /tmp/${comarcalimpia}.html | grep Coord | awk 'FNR == 1' | cut -d ] -f3 | cut -d \/ -f1) 
					fi
					pobla=$(lynx --dump /tmp/${comarcalimpia}.html | awk 'f{print;f=0} /Pobla/{f=1}' | head -n 1 | sed "s|(.*)||" | sed "s|^.*\(Total.*$\)|\1|") 
					if [ "${comarcalimpia}" = "Valle_de_Aran" ]; then pobla="Total	9971 hab."; fi
					comarca="${comarca}"$(printf '\t\t%s\n' "<tr><td>${coord}</td>") 
					comarca="${comarca}"$(printf '\t\t\t%s\n' "<td><a href=\"/Comarcas/${comarcalimpia}/index.html\" title=\"Redama internet rural ilimitado comarca de ${line}\">${line}</a></td>") 
					comarca="${comarca}"$(printf '\t\t%s\n' "<td>${pobla}</td></tr>")
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
		done <"${tmpcomarcas}" 
	else
		lynx --dump "${wikicomarcas}" | awk '/Comarcas\[/{t=1}; t==1{print; if (/Eco/ || /Demo/ || /Part/){c++}}; c==1{exit}' > "${tmpcomarcas}" && \
		for comarcalimpia in $(varsanitizer "`cat "${tmpcomarcas}" | tr ] '\n' | grep '^[A-Z]' | sed "s|\[.*||g" | sed "s|(.*)||g" | sed "s|[,.]||g" | sed "s| y $||g" | sed "s| $||g" | sed '1d' | sed '$d'`" "left"); do
			if [ $(echo ${comarcalimpia} | wc -c) -lt 20 ]; then
				if [ "${comarcalimpia}" = "Valles" ]; then comarcalimpia="Valles_Oriental"; fi;
				if [ "${comarcalimpia}" = "Noya" ]; then comarcalimpia="Noya_(comarca_de_Cataluña)"; fi;
				if [ "${comarcalimpia}" = "Selva" ]; then comarcalimpia="Selva_(comarca)"; fi;
				line=$(varsanitizer "${comarcalimpia}" "right")				
				if [ $(curl -s --head "https://es.wikipedia.org/wiki/${comarcalimpia}" | head -n 1 | awk '{print $2}') != "404" ]; then
					wget -O "/tmp/${comarcalimpia}.html" "https://es.wikipedia.org/wiki/${comarcalimpia}"
					coord=$(lynx --dump /tmp/${comarcalimpia}.html | grep Coord | awk 'FNR == 2' | cut -d ] -f3 | cut -d \/ -f1) 
					if [ $(echo $coord | head -c 1) != 4 ]; then
						coord=$(lynx --dump /tmp/${comarcalimpia}.html | grep Coord | awk 'FNR == 1' | cut -d ] -f3 | cut -d \/ -f1) 
					fi
					pobla=$(lynx --dump /tmp/${comarcalimpia}.html | awk 'f{print;f=0} /Pobla/{f=1}' | head -n 1 | sed "s|(.*)||" | sed "s|^.*\(Total.*$\)|\1|") 
					
					comarca="${comarca}"$(printf '\t\t%s\n' "<tr><td>${coord}</td>") 
					comarca="${comarca}"$(printf '\t\t\t%s\n' "<td><a href=\"/Comarcas/${comarcalimpia}/index.html\" title=\"Redama internet rural ilimitado comarca de ${line}\">${line}</a></td>") 
					comarca="${comarca}"$(printf '\t\t%s\n' "<td>${pobla}</td></tr>")
				fi
			fi 
		done
	fi && \
 	sed -i "s|/COMARCA/|${comarca}|" "${basepath}/Provincias/${provincia_limpia}/article.html" && \
 	uri="https%3A%2F%2Fcatalunya.redama.es%2FProvincias%2F${provincia_limpia}%2Findex.html" && \
	sed -i "s|/URI/|${uri}|" "${basepath}/Provincias/${provincia_limpia}/footer.html" && \
	cat "${basepath}/Provincias/${provincia_limpia}/header.html" > "${basepath}/Provincias/${provincia_limpia}/index.html" && \
	cat "${basepath}/Provincias/${provincia_limpia}/article.html" >> "${basepath}/Provincias/${provincia_limpia}/index.html" && \
	cat "${basepath}/Provincias/${provincia_limpia}/footer.html" >> "${basepath}/Provincias/${provincia_limpia}/index.html" && \
	rm -rf "${basepath}/Provincias/${provincia_limpia}/"{header.html,article.html,footer.html}
	
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
			for comarca in $(varsanitizer "`lynx --dump http://catalunya.redama.es/Provincias/${provi}/index.html | awk '/Coor/{t=1}; t==1{print; if (/Internet/){c++}}; c==1{exit}' | grep ] | cut -d ] -f2 | cut -d T -f1 | sed "s| *$||"`" "left"); do
				if [ "${comarca}" = "Valles" ]; then comarca="Valles_Oriental"; fi;
				if [ "${comarca}" = "Noya" ]; then comarca="Noya_(comarca_de_Cataluña)"; fi;
				if [ "${comarca}" = "Selva" ]; then comarca="Selva_(comarca)"; fi;
				if [ "${comarca}" = "El_Priorato" ]; then comarca="Priorato_(Tarragona)"; fi;
				if [ "${comarca}" = "Urgel" ]; then comarca="Urgel_(Cataluña)"; fi;
				[ ! -d "${basepath}/Comarcas/${comarca}" ] && mkdir "${basepath}/Comarcas/${comarca}"
				install -o "${userna}" -g "${groupna}" -m 0640 Comarcas/header.html  "${basepath}/Comarcas/${comarca}/header.html" 
				install -o "${userna}" -g "${groupna}" -m 0640 Comarcas/article.html  "${basepath}/Comarcas/${comarca}/article.html" 
				install -o "${userna}" -g "${groupna}" -m 0640 Comarcas/footer.html  "${basepath}/Comarcas/${comarca}/footer.html" 
				sed -i "s|/COMARCA/|${comarca}|g"  "${basepath}/Comarcas/${comarca}/header.html" && \
				sed -i "s|/COMARCA/|${comarca}|g"  "${basepath}/Comarcas/${comarca}/article.html" && \
				sed -i "s|/COMARCA/|${comarca}|g"  "${basepath}/Comarcas/${comarca}/footer.html" && \
				sed -i "s|/FECHA/|${fecha}|g"  "${basepath}/Comarcas/${comarca}/footer.html" && \
				#sed -i "s|/ESCUDOPROVINCIA/|Escudo_de_la_provincia_de_${provincia_limpia}.jpg|" "${basepath}/Provincias/${provincia_limpia}/article.html"
				wget -O "/tmp/${comarca}.html" "https://es.wikipedia.org/wiki/${comarca}"
				cat "/tmp/${comarca}.html" | awk "/<b>${comarca}/,/<\/p>/" > "${tmphtml}"
				wikipedia=$(lynx --dump "${tmphtml}" |  awk -v RS= 'NR==1'| sed -e 's|\]|\] |g' |  sed "s|\[[0-9]\]||g" |  sed "s|\[[0-9][0-9]\]||g" | sed "s|\^||g" | sed "s|&*&||g")
				awk '1;/\/WIKIPEDIA\//{exit}' "${basepath}/Comarcas/${comarca}/article.html" | awk 'NR>2 {print last} {last=$0}' > "${tmphtml}"
				echo "${wikipedia}" >> "${tmphtml}" 
				sed -n '/\/WIKIPEDIA\//,$p' "${basepath}/Comarcas/${comarca}/article.html"  | sed '1d' >> "${tmphtml}" 
				cat "${tmphtml}" > "${basepath}/Comarcas/${comarca}/article.html"
				#| awk '/Municipios\[/{t=1}; t==1{print; if (/Refe/){c++}}; c==1{exit}' | grep '\[' | sed '1d' | sed '$d' | tr '\[' '\n' | grep -v Localitz
			done
	fi
done



