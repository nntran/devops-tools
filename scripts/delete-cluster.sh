#!/bin/bash -eux

worker_count=3
master_count=3

docker-machine ls

for i in $(seq 1 ${master_count})
do
    docker-machine rm -y vm-master-${i}
done

# Worker nodes
for i in $(seq 1 ${worker_count})
do
    docker-machine rm -y vm-worker-${i}
done

docker-machine ls