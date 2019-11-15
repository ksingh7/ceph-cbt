# Radosbench / CBT Readiness

- Install pdsh, python-yaml ,python-lxml packages on ALL NODES
- The Master node in CBT is also known as Head node. From this node CBT test will be fired, make sure Head node can do passwordless SSH into all the client node as well as Ceph nodes. 
- Generate SSH key on Head node and add its public key on all Client nodes as well as Ceph nodes.
- On Head node, update /etc/hosts with Ceph OSD/MON hosts IP as well as client IPs (for convenience give them easy names)
- Verify you can SSH to rest of the client and Ceph nodes from the Head node

```
## This is a example, modify as per your need
for i in {1..6}; do ssh -o StrictHostKeyChecking=no node$i hostname ; done for i in {1..9}; do ssh -o StrictHostKeyChecking=no client$i hostname ; done
```

- CBT requires client nodes to access Ceph cluster and execute radosbench test. For this add ceph.conf and ceph keyring files on the client nodes
- Create /etc/ceph directory on all clients
```
## This is a example, modify as per your need
for i in {1..9} ; do ssh client$i yum install -y pdsh ceph-common ; done
for i in {1..9} ; do scp /etc/ceph/ceph.conf client$i:/tmp ; ssh client$i -t sudo mv /tmp/ceph.conf /etc/ceph/ceph.conf ; done
for i in {1..9} ; do scp /etc/ceph/ceph.client.admin.keyring client$i:/tmp ; ssh client$i -t sudo mv /tmp/ceph.client.admin.keyring /etc/ceph/ceph.client.admin.keyring  ; done
```
- Verify all client nodes can access Ceph cluster
```
for i in {1..9} ; do ssh client$i ceph osd stat ; done
```
- Create a pool for benchmarking and enable application on that pool
```
# ceph osd pool create rb-pool 1024 1024 
# ceph osd pool application enable rb-pool radosbench
```
- On Head node make sure to have CBT binaries in ``cbt`` directory
- Create a directlry from where we will run all benchmarking tests
```
cd cbt
mkdir -p IBM/output
```
- Based on your environment create a sample CBT file for 1 client

```
cd IBM
vim rb-write-read-4m-1-client.yaml
```

```
cluster:
  user: "root"
  head: "node1"
  clients: ["client1"]
  osds: ["node1", "node2", "node3", "node4", "node5", "node6"]
  mons:
    mtn16r11o001:
      a: "ceph-mon-discovery.ceph.svc.cluster.local"
  osds_per_node: 10
  iterations: 1
  rebuild_every_test: False
  use_existing: True
  clusterid: "ceph"
  tmp_dir: "/tmp/cbt"
  pool_profiles:
    replicated:
      pg_size: 1024
      pgp_size: 1024
      replication: 3
benchmarks:
  radosbench:
    op_size: [ 4194304 ]
    write_only: False
    time: 300
    concurrent_ops: [ 128 ]
    concurrent_procs: 1
    use_existing: True
    pool_profile: "replicated"
    pool_per_proc: False
    target_pool: "rb-pool"
    readmode: "seq"
    osd_ra: [131072]
```
- Execute your first CBT test
```
# cbt/cbt.py -a cbt/IBM/output/rb-write-read-4m-1-client cbt/IBM/rb-write-read-4m-1-client.yaml
```
- Once cbt is done executing the job, you can find the results in cbt/IBM/rb-write-read-4m-1-client directory

# Radosbench / CBT Client Scale Test

While benchmarking one should follow scientific testing methodology of changing one thing at a time. Under client scale test we will keep every component/setting constant and only change the number of client nodes in a linear order.

- To run radosbench test from 1 to 9 clients, create 9 different radosbench test files, by changing only the client line. (this is just example your, client count can vary)

```
cluster:
  user: "ks591a"
  head: "node1"
  clients: ["client1","client2","client3","client4","client5","client6","client7","client8","client9"]
  osds: ["node1", "node2", "node3"]
  mons:
    mtn16r11o001:
      a: "ceph-mon-discovery.ceph.svc.cluster.local"
  osds_per_node: 12
  iterations: 1
  rebuild_every_test: False
  use_existing: True
  clusterid: "ceph"
  tmp_dir: "/tmp/cbt"
  pool_profiles:
    replicated:
      pg_size: 8
      pgp_size: 8
      replication: 3
benchmarks:
  radosbench:
    op_size: [ 4194304 , 4096 ]
    write_only: False
    time: 300
    concurrent_ops: [ 128 ]
    concurrent_procs: 1
    use_existing: True
    pool_profile: "replicated"
    pool_per_proc: False
    target_pool: "cm434853-2"
    readmode: "seq"
    osd_ra: [131072]

```
- For convinience install screen on Head node (if you are familiar with it)
- Create a handy test runner script to automate test execution

# Results Parsing

- Pleaes note once results has been parsed, make sure to add the results to the Radosbench_Results.xlsx file , in the format provided. If you have added the results correctly, most likely you will get performance charts generated automatically.

```
cbt/getresults.sh
```
- To parse result of say 2Clients, 4M , Write Radosbench test, navigate to result directory and execute getresult.sh script

```
# cd /root/cbt/IBM/output/rb-write-read-4m-4k-2-client/00000000/Radosbench/osd_ra-00131072/op_size-04194304/concurrent_ops-00000128/write 
# sh /root/cbt/getresult.sh
```
- To execute radosbench on multiple clients in parallel use ``cbt/test_runner.sh 1 9``
- Once scale testing is completed you should have results in CBT archive directory

- To parse Write results with 4M block size results, execute

```
pattern=write; size=04194304 ; for i in {1..9} ; do cd /root/cbt/IBM/output/rb-write-read-4m-4k-$i-client/00000000/Radosbench/osd_ra-00131072/op_size-$size/concurrent_ops-00000128/$pattern ; sh /root/cbt/getresult.sh ; cd ; done
```
- You can now move Bandwidth(MB/sec) to excel for further processing

- To parse Read with 4M block size results, execute
```
pattern=seq; size=04194304 ; for i in {1..9} ; do cd /root/cbt/IBM/output/rb-write-read-4m-4k-$i-client/00000000/Radosbench/osd_ra-00131072/op_size-$size/concurrent_ops-00000128/$pattern ; sh /root/cbt/getresult.sh ; cd ; done
```
- To parse Write with 4K block size results, execute
```
pattern=write; size=00004096 ; for i in {1..9} ; do cd /root/cbt/IBM/output/rb-write-read-4m-4k-$i-client/00000000/Radosbench/osd_ra-00131072/op_size-$size/concurrent_ops-00000128/$pattern ; sh /root/cbt/getresult.sh ; cd ; done
```
- To parse Read with 4K block size results, execute
```
pattern=seq; size=00004096 ; for i in {1..9} ; do cd /root/cbt/IBM/output/rb-write-read-4m-4k-$i-client/00000000/Radosbench/osd_ra-00131072/op_size-$size/concurrent_ops-00000128/$pattern ; sh /root/cbt/getresult.sh ; cd ; done
```