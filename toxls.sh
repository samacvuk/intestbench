#!/bin/bash

LOG_DIR=logs
XLS_FILE=logs/intestbench.xls

[ ! -d $LOG_DIR ] && mkdir -p $LOG_DIR 
[ "$(ls -A $LOG_DIR)" ] || exit 1

data=`cat $LOG_DIR/*.log`

echo "timestamp;bench;h1;h2;wmetric;wmetric_al;pnr" > $XLS_FILE

echo $data | while read line
do
	ts=`echo $line | awk '{print $1}' | sed 's/:.*$//g'`
	bench=`echo $line | awk '{print $2}'`
	h1=`echo $line | awk '{print $3}' | sed 's/^.*://g'`
	h2=`echo $line | awk '{print $4}' | sed 's/^.*://g'`
	wmetric=`echo $line | awk '{print $5}' | sed 's/^.*://g'`
	wmetric_al=`echo $line | awk '{print $6}' | sed 's/^.*://g'`
	pnr=`echo $line | awk '{print $7}' | sed 's/^.*://g'`

	echo "$ts;$bench;$h1;$h2;$wmetric;$wmetric_al;$pnr" >> $XLS_FILE
done
