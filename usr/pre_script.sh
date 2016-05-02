#!/bin/bash

HOME_HADOOP=/home/ubuntu/hadoop2-install-scripts/

#spark
HOME_HADOOP_BIN=/home/ubuntu/hadoop2-install-scripts/HiBench/workloads/terasort/prepare/
#HOME_HADOOP_BIN=/home/ubuntu/hadoop2-install-scripts/HiBench/workloads/kmeans/prepare/
#HOME_HADOOP_BIN=/home/ubuntu/hadoop2-install-scripts/HiBench/workloads/pagerank/prepare/

#hadoop
#HOME_HADOOP_BIN=/home/ubuntu/hadoop2-install-scripts/HiBench/workloads/wordcount/prepare

function pre_script
{
	remote_exec $base_host_ip "pushd $HOME_HADOOP; bash deploy-hadoop2.sh -u"
	remote_exec $base_host_ip "pushd $HOME_HADOOP; bash deploy-hadoop2.sh -d"
	remote_exec $base_host_ip "pushd $HOME_HADOOP; /tmp/hadoop-2.7.2/bin/hdfs dfsadmin -safemode leave"
	remote_exec $base_host_ip "source /home/ubuntu/hadoop2-install-scripts/hadoop.env; pushd $HOME_HADOOP_BIN; bash prepare.sh"

	echo "Pre script completed."
}
