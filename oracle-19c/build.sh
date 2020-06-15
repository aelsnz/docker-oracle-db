#!/bin/bash

  v_tag="19c"
  base_image="oracle-db"
  owner="aelsnz"

  docker build -f dockerfiles/Dockerfile -t ${owner}/${base_image}:${v_tag} . > /tmp/oracle-db-19c-base-build.out
  docker run -h dev19c --name dev19c ${owner}/${base_image}:${v_tag} /bin/true
  cd /tmp
  docker export --output=dev19c.tar dev19c
  cat dev19c.tar | docker import - ${owner}/${base_image}:${v_tag}-tmp
  rm -rf dev19c.tar
  cd -
  docker build --build-arg BASE="${owner}/${base_image}:${v_tag}-tmp" -f dockerfiles/Dockerfile-Final -t ${owner}/${base_image}:${v_tag} .

  if [ $? -eq 0 ]; then
	  docker rmi ${owner}/${base_image}:${v_tag}-tmp
  else
	  echo "Review build log as build exit with non zero exit status"   
	  exit 1
  fi