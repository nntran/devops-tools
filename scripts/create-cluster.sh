#!/bin/bash -eux

default_driver=virtualbox
worker_count=3
master_count=3

if [ -z "${DOCKER_MACHINE_DRIVER}" ]; then
    DOCKER_MACHINE_DRIVER=$default_driver
fi

# REGISTRY_MIRROR_OPTS="--engine-registry-mirror https://jxus37ac.mirror.aliyuncs.com"
# INSECURE_OPTS="--engine-insecure-registry 192.168.99.0/24"
STORAGE_OPTS="--engine-storage-driver overlay2"

MACHINE_OPTS="${STORAGE_OPTS} ${INSECURE_OPTS} ${REGISTRY_MIRROR_OPTS}"

# Master node
docker-machine create -d ${DOCKER_MACHINE_DRIVER} ${MACHINE_OPTS} vm-master-1

# Create Swarm Manager
MASTER_IP=`docker-machine ip vm-master-1`
echo "MAster IP: ${MASTER_IP}"

eval $(docker-machine env vm-master-1)
docker swarm init --advertise-addr ${MASTER_IP}

# Fetch Tokens
MASTER_TOKEN=`docker swarm join-token manager | grep token | awk '{ print $5 }'`
WORKER_TOKEN=`docker swarm join-token worker | grep token | awk '{ print $5 }'`

# Managers
if [ "${master_count}" -gt 2 ]; then
    for i in $(seq 2 ${master_count})
    do
        docker-machine create -d ${DOCKER_MACHINE_DRIVER} ${MACHINE_OPTS} vm-master-${i}

        eval $(docker-machine env vm-master-${i})
        docker swarm join --token ${MASTER_TOKEN} ${MASTER_IP}:2377
    done
fi

# Worker nodes
for i in $(seq 1 ${worker_count})
do
    docker-machine create -d ${DOCKER_MACHINE_DRIVER} ${MACHINE_OPTS} vm-worker-${i}

    eval $(docker-machine env vm-worker-${i})
    docker swarm join --token ${WORKER_TOKEN} ${MASTER_IP}:2377
done

docker-machine ls