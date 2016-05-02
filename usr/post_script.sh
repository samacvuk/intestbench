#!/bin/bash

HOME_HADOOP=/home/ubuntu/hadoop2-install-scripts/
#HOME_HADOOP_BIN=/home/ubuntu/hadoop2-install-scripts/HiBench-yarn/'sort'/bin/
#HOME_HADOOP_BIN=/home/ubuntu/hadoop2-install-scripts/HiBench-yarn/wordcount/bin/
#HOME_HADOOP_BIN=/home/ubuntu/hadoop2-install-scripts/HiBench-yarn/pagerank/bin/

function post_script
{
	remote_exec $base_host_ip "pushd $HOME_HADOOP; bash deploy-hadoop2.sh -u"

        echo "Post script completed."
}
