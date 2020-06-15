#!/bin/bash

# Basic script to build base oracle linux images 
# for oel5,6,7
# This is just to add a set of standard pre-requisite packages and a few nice to haves
# ideally you want to keep images small, but these will run Oracle... so might not
# end that small, so might as well load a few extra useful packages
#

list="oel5 oel6 oel7"
base_image="oraclelinux"
owner="aelsnz"

for c1 in ${list}
do
  docker build -f dockerfiles/Dockerfile_${c1} -t ${owner}/${base_image}:${c1} . > /tmp/${base_image}.${c1}-build.out
  docker rm ${c1}
  docker run -h ${c1} --name ${c1} ${owner}/${base_image}:${c1} /bin/true
  cd /tmp
  docker export --output=/tmp/${base_image}-${c1}.tar ${c1}
  docker rm ${c1}
  docker rmi ${owner}/${base_image}:${c1}
  cat /tmp/${base_image}-${c1}.tar | docker import - ${owner}/${base_image}:${c1}
  rm -rf /tmp/${base_image}-${c1}.tar
  cd -
done
