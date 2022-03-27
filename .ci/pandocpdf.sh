#!/bin/bash


echo "Hello world!"
echo "This is a message from 'pandocpdf.sh'."


export GITHUBCI=y

bash buildall.sh --force
