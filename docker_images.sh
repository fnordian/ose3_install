#!/usr/bin/env bash
#
# Functions to import/export docker images on a local backup directory (${DOCKER_BACKUP_DIR}). Saves download time for every single image.
#
# Adapted from https://gist.github.com/lalyos/50ac584bf0dc6ccb061f
# 
get-image-field() {
  local imageId=$1
  local field=$2
  : ${imageId:? reuired}
  : ${field:? required}
 
  docker images --no-trunc|sed -n "/${imageId}/ s/ \+/ /gp"|cut -d" " -f $field
}
 
get-image-name() {
  get-image-field $1 1
}
 
get-image-tag() {
  get-image-field $1 2
}
 
docker_backup_all_images() {
  local ids=$(docker images -q)
  local name safename tag

  for id in $ids; do
    name=$(get-image-name $id)
    tag=$(get-image-tag $id)
    if [[  $name =~ / ]] ; then
       dir=${DOCKER_BACKUP_DIR}/${name%/*}
       mkdir -p $dir
    fi

    echo "[INFO] Saving $name:$tag => ${COMMAND}"
    if [ -f ${DOCKER_BACKUP_DIR}/$name.$tag.dim ] ; then
      echo "[WARN] File already exists: ${DOCKER_BACKUP_DIR}/$name.$tag.dim"
    else
      COMMAND="docker save -o ${DOCKER_BACKUP_DIR}/$name.$tag.dim $name:$tag"  
      (time  ${COMMAND}) 2>&1 | grep real
    fi
  done
}

docker_restore_all_images() {
  local name safename noextension tag
 
  for image in $(find ${DOCKER_BACKUP_DIR} -name \*.dim); do
    echo [INFO] Loading $image
    tar -Oxf $image repositories
    echo
    docker load -i $image
  done
}
