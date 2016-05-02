#!/bin/bash 
# LXC Version (bench runs in host)
#
# Marlon Ortiz Sanhudo <marlon.ortiz19@gmail.com>
# modified by Kassiano 2-2-16
# added stress test per scheduler
# removed sleeps

. functions/global_functions
. functions/bench_functions
. functions/log_functions

. usr/pre_script.sh
. usr/post_script.sh
. drvs/lxc.sh
#. drvs/vmware.sh 

CMD_OPTIONS=$(getopt -n "$0"  -o ahepc --long "son0,son1,son2,son3,son4,son5,son6,son7,son8,help,execute,prepare,custom,alone" -- "$@")
if [ $? -ne 0 ]; then exit 1
fi
eval set -- "$CMD_OPTIONS"

YELLOW='\e[1;33m'

percent_h1=100
percent_h2=100
percent_step=20
restrict_res="no"

function load_default_values
{
	sleep 10
	unrestrict_cpu_cpuset

        if [ $restrict_res = "yes" ]; then
                percent_step=20
        else
                percent_step=100
        fi

	percent_h1=100
	percent_h2=100
}

function check_requirements
{
        # check conectivity
        check_ip_connection
        check_ssh_connection

        # check package requirements
        check_packages
}

function prepare
{
      load_variables_from_file "config_file"
      load_son_config_file "son_config_file"

      #vi_stop
      #vi_start

      check_requirements
      #load_default_values
}

function execute_all
{
	for i in `seq 0 8`
	do
		[ $i -eq 1 ] && continue
#		[ $i -eq 7 ] && continue

		son$i $3
	done

	#vi_stop
	
	echo "Output file created in the working directory"
	echo "Finished!"
}


help()
{
cat << EOF
 
This script installs all requirements in both virtual instances. Configure the
environment in ConfigFile file before you start. 
 
USAGE: intestbench.sh [options]
 
OPTIONS:
   -e, --execute_all      Start all tests in both hosts

   -a, --alone		  Start your application in host base

   --son0,  		  CPU stress test

   --son1,		  Memory stress test      

   --son2,		  Sync HDD stress test      

   --son3, 		  Direct HDD stress test      

   --son4,	          Seq. write HDD stress test      

   --son5,		  Rdn write HDD stress test        

   --son6,		  Seq. read HDD stress test       

   --son7,		  Rdn read HDD stress test      

   --son8,		  Cache stress test      

   -c, --custom		  example? 

   -p, --prepare          prepare and check system's requirements

   -h, --help             Show this message.

EOF
}

if [[ $3 != "" ]] ; then
	restrict_res=$3
fi

while true;
do
  case "$1" in

    -h|--help)
      help
      exit 0
      ;;
    -e|--execute_all)
      prepare
      execute_all
      break
      ;;
    -p|--prepare)
      prepare
      break
      ;;
    -c|--custom)
      prepare
      bench_son "${son_cmd[$3]}" "${son_param[$3]}"
      break
      ;;
    -a|--alone)
      prepare
      bench_alone_exec
      break
      ;;
    --son0)
      prepare
      son0
      break
      ;;
    --son1)
      prepare
      son1
      break
      ;;
    --son2)
      prepare
      son2
      break
      ;;
    --son3)
      prepare
      son3
      break
      ;;
    --son4)
      prepare
      son4
      break
      ;;
    --son5)
      prepare
      son5
      break
      ;;
    --son6)
      prepare
      son6
      break
      ;;
    --son7)
      prepare
      son7
      break
      ;;
    --son8)
      prepare
      son8
      break
      ;;
    --)
      help
      break
      ;;
  esac
done

exit 0
