#!/usr/bin/bash

#Comunidad autonoma de Catalunya

wikiprovincias="$(mktemp)"".html"
fecha=$(date +"%d/%m/%Y")
basepath=$(pwd)"/../catalunya.redama.es"
uid=$(id -u)
userna=$(id -nu $uid)
groupna=$(getent group "${userna}" | cut -d : -f1)

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
	for filename in "Sanitized/*"; do
		$COMPOSITE -compose multiply -gravity SouthWest watermark/watermark.jpg "${filename}" "Watermarked/"$(basename "${filename}" | cut -d . -f1)".jpg"
	done
	for filename in "Watermarked/*"; do
		$COMPOSITE -compose multiply -gravity SouthEast watermark/watermark2.jpg "${filename}" "/tmp"/"$(basename "${filename}")"
		mv "/tmp"/"$(basename "${filename}")" "${filename}"
	done
}

read -p "Escribe la provincia de añadir a tu web, la primera letra MAIUSC " provincia
wget -O "${wikiprovincias}" https://es.wikipedia.org/wiki/Anexo:Provincias_y_ciudades_aut%C3%B3nomas_de_Espa%C3%B1a
gawk -i inplace '/wikitable/,/\/table/' "${wikiprovincias}"
install -o "${userna}" -g "${groupna}" -m 0640 header.html  "${basepath}/Provincias/${provincia}/header.html"
install -o "${userna}" -g "${groupna}" -m 0640 article.html  "${basepath}/Provincias/${provincia}/article.html"
install -o "${userna}" -g "${groupna}" -m 0640 article.html  "${basepath}/Provincias/${provincia}/footer.html"
sed -i "s|/PROVINCIA/|${provincia}|g"  "${basepath}/Provincias/${provincia}/header.html"
sed -i "s|/PROVINCIA/|${provincia}|g"  "${basepath}/Provincias/${provincia}/article.html"
sed -i "s|/PROVINCIA/|${provincia}|g"  "${basepath}/Provincias/${provincia}/footer.html"
sed -i "s|/FECHA/|${fecha}|g"  "${basepath}/Provincias/${provincia}/footer.html"


read -p "Quieres sanear la carpeta de los escudos de municipios? 1/0 " ctrl
[[ $ctrl ]] && \
	cd "Img/" && \
	sanitizer
read -p "Quieres aplicar filigrana a todas las imagenes? 1/0 " ctrl
[[ $ctrl ]] && \
	mark

