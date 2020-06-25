#!/usr/bin/env bash

curl -s https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh | bash -s -- -g 8.3.0

curlfiles=""
for file in "/home/travis/build/iMintty/wow-action-camera/.release"/*
do
    if [ ${file: -4} == ".zip" ]
    then
        curlfiles="$curlfiles -F $(basename $file)=@$file"
    fi
done

curl $curlfiles $DISCORD_WEBHOOK_RELEASE
echo $curlfiles