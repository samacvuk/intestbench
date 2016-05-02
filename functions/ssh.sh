#!/bin/bash

user=$1
host=$2
cmd=$3

ret=$(rsh $1\@$2 "$3" ; echo $?)
_status=$(echo $ret | awk '{ print $NF }')
[ $_status -eq 255 ] && echo "Connection failure." && exit 1

