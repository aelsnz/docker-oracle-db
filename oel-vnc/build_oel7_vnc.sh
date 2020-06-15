#!/bin/bash

# Basic script to build base oracle linux images for oel5,6,7

c1="oel7-vnc"
new_image="oraclelinux"

echo "building ... ${new_image}:${c1}"
docker build -f dockerfiles/Dockerfile -t aelsnz/${new_image}:${c1} . > /tmp/${new_image}.${c1}-build.out



