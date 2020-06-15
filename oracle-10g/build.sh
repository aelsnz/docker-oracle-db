#!/bin/bash
#
# Description:
#  The following script is used to build the 10g database image.  It will go through the following to create a nice small image
#  First it creates the base install, with 10.2.0.5 patch applied, the end resulting image is big - about 12G, but sqaushing the
#  layers by doing export/import cuts it down to about 2.6G - without database. 
#
#  You can adjust the Dockerfile to create the database, or you can easily create it afterwards
#
#
  v_tag="10g"
  base_image="oracle-db"
  owner="aelsnz"

  docker build --shm-size=4294967296 -f dockerfiles/Dockerfile -t ${owner}/${base_image}:${v_tag} . > /tmp/${base_image}.${v_tag}-build.out
  docker run -h tmp10g --name tmp10g ${owner}/${base_image}:${v_tag} /bin/true
  cd /tmp
  docker export --output=${base_image}-${v_tag}.tar tmp10g
  docker rm tmp10g
  docker rmi ${owner}/${base_image}:${v_tag}
  cat ${base_image}-${v_tag}.tar | docker import - ${owner}/${base_image}:${v_tag}-tmp
  rm -rf ${base_image}-${v_tag}.tar
  cd -

  # this image will re-use previous and add layer with default oracle user login
  docker build --shm-size=4294967296 --build-arg BASE="${owner}/${base_image}:${v_tag}-tmp" -f dockerfiles/Dockerfile-Final -t ${owner}/${base_image}:${v_tag} .

  # if exit code 0 - meaning all should be good, lets cleanup temporary image
  if [ $? -eq 0 ]; then
    docker rmi ${owner}/${base_image}:tmp
  fi
