#!/bin/bash
mkdir /tmp/cbt/log
for i in $(seq $1 $2); do
   echo "*************** Starting Test-$i ***************"
   /home/ks591a/cbt/cbt.py -a /home/ks591a/cbt/att/output/rb-write-read-4m-4k-$i-client /home/ks591a/cbt/att/rb-write-read-4m-4k-$i-client.yaml > /tmp/cbt/log/rb-write-read-4m-4k-$i-client.yaml 2>&1
   echo "*************** Test-$i completed ***************"
   sleep 120 
done
