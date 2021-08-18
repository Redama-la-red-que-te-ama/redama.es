#!/bin/bash

DATE=$(date +%d%m%Y)
DATE_RELEASE=$(date +"%d/%m/%Y %H:%m:%S")
HOMEWRK="`pwd`/../"
REPO=$(basename `pwd`)
RELEASE="/$REPO$DATE.tar"

echo "git add, commit, sign and push \n"
cd "$HOMEWRK$REPO"
echo "check branch \n"
BRANCHCTRL=$(git branch | grep $DATE)
if [ -z "${BRANCHCTRL}" ]
then
	git checkout -b taglio-$DATE
	git push --set-upstream origin taglio-$DATE
fi	
git add .
git commit -S
git push --force
