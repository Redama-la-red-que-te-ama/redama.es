#!/bin/bash

#Comunidad autonoma de Catalunya

wikiprovincias="$(mktemp)"".html"
fecha=$(date +"%d/%m/%Y")

read -p "Escribe la provincia de añadir a tu web " provincia
wget -O "${wikiprovincias}" https://es.wikipedia.org/wiki/Anexo:Provincias_y_ciudades_aut%C3%B3nomas_de_Espa%C3%B1a
gawk -i inplace '/wikitable/,/\/table/' "${wikiprovincias}"
lynx --dump "${wikiprovincias}"

