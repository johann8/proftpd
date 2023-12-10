#!/bin/bash

# set variables
_VERSION=0.1.0

# create build
docker build -t johann8/proftpd:${_VERSION} .
_BUILD=$?
if ! [ ${_BUILD} = 0 ]; then
   echo "ERROR: Docker Image build was not successful"
   exit 1
else
   echo "Docker Image build successful"
   docker images -a 
   docker tag johann8/proftpd:${_VERSION} johann8/proftpd:latest
fi

#push image to dockerhub
if [ ${_BUILD} = 0 ]; then
   echo "Pushing docker images to dockerhub..."
   docker push johann8/proftpd:latest
   docker push johann8/proftpd:${_VERSION}
   _PUSH=$?
   docker images -a |grep proftpd
fi


#delete build
if [ ${_PUSH=} = 0 ]; then
   echo "Deleting docker images..."
   docker rmi johann8/proftpd:latest
   #docker images -a
   docker rmi johann8/proftpd:${_VERSION}
   #docker images -a
   #docker rmi alpine:3.17
   docker images -a
fi

# Delete none images
# docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
