#!/bin/bash
#
# Description: 
#  This script can be used to build the 18c database container for testing
#  Note: You must download the oracle software and place it in the software sub folder.
# 
#  The process is to build the base image, then squash the layers to create smaller image as the image is a bit big
#  this is making use of the export/import option - this does take time, but space saving is worth it.
#

  v_tag="18c"
  base_image="oracle-db"
  owner="aelsnz"

  docker build -f dockerfiles/Dockerfile -t ${owner}/${base_image}:${v_tag} . > /tmp/oracle-db-18c-base-build.out
  docker run -h dev18c --name dev18c ${owner}/${base_image}:${v_tag} /bin/true
  cd /tmp
  docker export --output=dev18c.tar dev18c
  cat dev18c.tar | docker import - ${owner}/${base_image}:${v_tag}-tmp
  rm -rf dev18c.tar
  cd -
  docker build --build-arg BASE="${owner}/${base_image}:${v_tag}-tmp" -f dockerfiles/Dockerfile-Final -t ${owner}/${base_image}:${v_tag} .

  if [ $? -eq 0 ]; then
	  docker rmi ${owner}/${base_image}:${v_tag}-tmp
  else
	  echo "Review build log as build exit with non zero exit status"   
	  exit 1
  fi