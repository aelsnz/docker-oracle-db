#!/bin/bash
#
# Description: 
#  This script can be used to build the 12c database container for testing
#  Note: You must download the oracle software and place it in the software sub folder.
# 
#  The process is to build the base image, then squash the layers to create smaller image as the image is a bit big
#  this is making use of the export/import option - this does take time, but space saving is worth it.
#

  v_tag="12c"
  base_image="oracle-db"
  owner="aelsnz"

  docker build -f dockerfiles/Dockerfile -t ${owner}/${base_image}:${v_tag} . > /tmp/oracle-db-12c-base-build.out
  docker run -h temp${v_tag} --name temp${v_tag} ${owner}/${base_image}:${v_tag} /bin/true
  cd /tmp
  docker export --output=temp${v_tag}.tar temp${v_tag}
  cat temp${v_tag}.tar | docker import - ${owner}/${base_image}:${v_tag}-tmp
  rm -rf temp${v_tag}.tar
  cd -
  docker build --build-arg BASE="${owner}/${base_image}:${v_tag}-tmp" -f dockerfiles/Dockerfile-Final -t ${owner}/${base_image}:${v_tag} .
  if [ $? -eq 0 ]; then
	  docker rmi ${owner}/${base_image}:${v_tag}-tmp
  else
	  echo "Review build log as build exit with non zero exit status"   
	  exit 1
  fi
