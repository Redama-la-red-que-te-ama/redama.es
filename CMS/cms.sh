#!/usr/bin/ksh

#Comunidad autonoma de Catalunya

wikiprovincias="$(mktemp)"".html"
fecha=$(date +"%d/%m/%Y")
basepath=$(pwd)"/../catalunya.redama.es"
uid=$(id -u)
userna=$(id -nu $uid)
groupna=$(getent group "${userna}" | cut -d : -f1)

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

