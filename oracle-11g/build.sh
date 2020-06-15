#!/bin/bash
# Description:
#   Basic script to build base oracle 11204 images for oracle linux 6 and 7

list="oel6 oel7"
base_image="oracle-db"
owner="aelsnz"

for c1 in ${list}
do
  v_tag="11204-${c1}"
  docker build -f dockerfiles/Dockerfile_${c1} -t ${owner}/${base_image}:${v_tag} . > /tmp/${base_image}.${v_tag}-build.out
  
  docker rm ${c1}
  docker run -h ${c1} --name ${c1} ${owner}/${base_image}:${v_tag} /bin/true
  cd /tmp
  docker export --output=${base_image}-${v_tag}.tar ${c1}
  docker rm ${c1}
  docker rmi ${owner}/${base_image}:${v_tag}
  cat ${base_image}-${v_tag}.tar | docker import - ${owner}/${base_image}:${v_tag}-tmp
  rm -rf ${base_image}-${v_tag}.tar
  cd -

  # this image will re-use previous and add layer with default oracle user login
  docker build --build-arg BASE="${owner}/${base_image}:${v_tag}-tmp" -f dockerfiles/Dockerfile-Final -t ${owner}/${base_image}:${v_tag} .
  if [ $? -eq 0 ]; then
	docker rmi ${owner}/${base_image}:${v_tag}-tmp
  else
	echo "Review build log as build exit with non zero exit status"   
	exit 1
  fi
done
