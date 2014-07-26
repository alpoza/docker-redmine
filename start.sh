#!/bin/bash
id=$(docker run -d -p 3000 jbbarth/redmine)
host=${DOCKER_HOST:-127.0.0.1}
ip=$(echo $host|perl -pe 's#^([^:]+://)?([^:]+)(:.*)?$#$2#')
echo $id http://$(docker port $id 3000 | sed "s/0.0.0.0/$ip/")
