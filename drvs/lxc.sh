#!/bin/bash

function restrict_cpu
{
        p1=$1
        p2=$2
	
	[ $p1 -le 0 ] && return

        echo "Setting CPU share of $base_host_domain_name to $p1% and $stress_host_domain_name to $p2%"
	sleep 5
        lxc-cgroup -n $base_host_domain_name cpu.shares $p1
	sleep 5
        lxc-cgroup -n $stress_host_domain_name cpu.shares $p2
}

function unrestrict_cpu_cpuset
{
	echo "unrestricting cpuset..."
	
	sleep 5
	lxc-cgroup -n $base_host_domain_name cpuset.cpus 0-31
	sleep 5
        lxc-cgroup -n $stress_host_domain_name cpuset.cpus 0-31
	
	TOTAL_CPU=`cat /proc/cpuinfo | grep processor | awk '{print $3}' | tail -n 1`
	TOTAL_CPU=`expr $TOTAL_CPU + 1`
	remote_exec $base_host_ip "echo $TOTAL_CPU > /tmp/alloc_cpu" 
	remote_exec $stress_host_ip "echo $TOTAL_CPU > /tmp/alloc_cpu" 
}

function restrict_cpu_cpuset
{
        echo "Dividing number of CPUs among Hosts"

	#lxc-cgroup -n $base_host_domain_name cpuset.cpus 0,1,2,3,4,5,6,7
	#lxc-cgroup -n $stress_host_domain_name cpuset.cpus 8,9,10,11,12,13,14,15

	#Proj02
	sleep 5
	lxc-cgroup -n $base_host_domain_name cpuset.cpus 0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30
	sleep 5
        lxc-cgroup -n $stress_host_domain_name cpuset.cpus 1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31

	remote_exec $base_host_ip "echo 16 > /tmp/alloc_cpu" 
	remote_exec $stress_host_ip "echo 16 > /tmp/alloc_cpu" 

	#cerrado 32 cores
	#lxc-cgroup -n $base_host_domain_name cpuset.cpus 0,2,4,6,8,10,12,14,16,18,20,22
        #lxc-cgroup -n $stress_host_domain_name cpuset.cpus 1,3,5,7,9,11,13,15,17,19,21,23
        
	#atalntica 16 cores
	#lxc-cgroup -n $base_host_domain_name cpuset.cpus 0,2,4,6,8,10,12,14
        #lxc-cgroup -n $stress_host_domain_name cpuset.cpus 1,3,5,7,9,11,13,15
}

function restrict_disk
{

        p1=$1
        p2=$2

	[ $p1 -le 0 ] && return

        echo "Setting disk throughput of $base_host_domain_name to $p1% and $stress_host_domain_name to $p2%"
	
	h1_disk_alloc=$(((p1 * maximum_disk_throughput)/100))
        h2_disk_alloc=$(((p2 * maximum_disk_throughput)/100))

	echo "8:0 $h1_disk_alloc" > /sys/fs/cgroup/blkio/lxc/$base_host_domain_name/blkio.throttle.write_bps_device 
	echo "$h1_disk_alloc" > /sys/fs/cgroup/blkio/lxc/$base_host_domain_name/blkio.throttle.buffered_write_bps
	echo "8:0 $h2_disk_alloc" > /sys/fs/cgroup/blkio/lxc/$stress_host_domain_name/blkio.throttle.write_bps_device 
	echo "$h2_disk_alloc" > /sys/fs/cgroup/blkio/lxc/$stress_host_domain_name/blkio.throttle.buffered_write_bps

	echo "8:0 $h1_disk_alloc" > /sys/fs/cgroup/blkio/lxc/$base_host_domain_name/blkio.throttle.read_bps_device 
	echo "8:0 $h2_disk_alloc" > /sys/fs/cgroup/blkio/lxc/$stress_host_domain_name/blkio.throttle.read_bps_device 
}

function restrict_mem
{
        p1=$1
        p2=$2

	[ $p1 -le 0 ] && return

        echo "Setting memory of $base_host_domain_name to $p1% and $stress_host_domain_name to $p2%"

	h1_mem_alloc=$(((p1 * total_memory_in_bytes)/100/1024/1024/1024))
	h2_mem_alloc=$(((p2 * total_memory_in_bytes)/100/1024/1024/1024))
	
	remote_exec $base_host_ip "echo $h1_mem_alloc > /tmp/alloc_mem" 
	remote_exec $stress_host_ip "echo $h2_mem_alloc > /tmp/alloc_mem" 

        h1_mem_alloc=${h1_mem_alloc%.*}
        h2_mem_alloc=${h2_mem_alloc%.*}

        lxc-cgroup -n $base_host_domain_name memory.limit_in_bytes $h1_mem_alloc"G"
        lxc-cgroup -n $stress_host_domain_name memory.limit_in_bytes $h2_mem_alloc"G"
}

function vi_start
{
        echo "Starting up virtual instances $base_host_domain_name and $stress_host_domain_name"

	lxc-start -n $base_host_domain_name -d
	lxc-start -n $stress_host_domain_name -d
	
	sleep 10
}

function vi_stop
{
        echo "Stopping virtual instances $base_host_domain_name and $stress_host_domain_name"

	lxc-stop -n $base_host_domain_name
	lxc-stop -n $stress_host_domain_name

	sleep 10
}
