#!/bin/bash
#Vmware Version 6.0
#Fabian Lorenzo <fabian.lorenzo@acad.pucrs.br>, Miguel Xavier <xleugim@gmail.com>
#Driver for Vmware's Vsphere

function restrict_mem
{
	p1=$1
	p2=$2

	#Get identification	
	rsh root@$vsphere_ip esxcli vm process list | grep -B1 World | sed 's/^ *W.* //g' | grep -v "-" > /tmp/vm_name_worldID_alloc
	VM_WORLD_ID_1=$(head -2 /tmp/vm_name_worldID_alloc | tail -1)
	VM_WORLD_ID_2=$(head -4 /tmp/vm_name_worldID_alloc | tail -1)

	vm1_mem_alloc=$(((p1 * total_memory_in_bytes)/100/1024/1024))
	vm2_mem_alloc=$(((p2 * total_memory_in_bytes)/100/1024/1024))

	vm1_mem_alloc=$(((1024 - (vm1_mem_alloc%1024)) + vm1_mem_alloc))
	vm2_mem_alloc=$(((1024 - (vm2_mem_alloc%1024)) + vm2_mem_alloc))	
        
	echo $vm1_mem_alloc | ssh $base_host_ip "cat > /tmp/alloc_mem" 
	echo $vm2_mem_alloc | ssh $stress_host_ip "cat > /tmp/alloc_mem" 

	echo "Setting memory of $base_host_domain_name to $p1% and $stress_host_domain_name to $p2%"
	
	#Turn Off VMs if they are powered on
	if [ -s "/tmp/vm_name_worldID_alloc" ]; then		
		rsh root@$vsphere_ip "esxcli vm process kill --type=soft --world-id=$VM_WORLD_ID_1"
		rsh root@$vsphere_ip "esxcli vm process kill --type=soft --world-id=$VM_WORLD_ID_2"
	fi
	
		
	#Change memory on .vmx files and boot VMs	
	rsh root@$vsphere_ip "sed -i 's/^memSize.*/memSize\ =\ \"$vm1_mem_alloc\"/g'" $vm1_config_file 
	rsh root@$vsphere_ip "sed -i 's/^memSize.*/memSize\ =\ \"$vm2_mem_alloc\"/g'" $vm2_config_file 

	rsh root@$vsphere_ip "vim-cmd vmsvc/reload $VM_ID_1"
	rsh root@$vsphere_ip "vim-cmd vmsvc/reload $VM_ID_2"
	rsh root@$vsphere_ip "vim-cmd vmsvc/power.on $VM_ID_1"
	rsh root@$vsphere_ip "vim-cmd vmsvc/power.on $VM_ID_2"
	sleep 25
}

function restrict_cpu
{
	p1=$1
	p2=$2
	TOTAL_SHARES=2000

	#Get identification	
	rsh root@$vsphere_ip esxcli vm process list | grep -B1 World | sed 's/^ *W.* //g' | grep -v "-" > /tmp/vm_name_worldID_alloc
	VM_WORLD_ID_1=$(head -2 /tmp/vm_name_worldID_alloc | tail -1)
	VM_WORLD_ID_2=$(head -4 /tmp/vm_name_worldID_alloc | tail -1)
	
	#Turn Off VMs if they are powered on
	if [ -s "/tmp/vm_name_worldID_alloc" ]; then		
		rsh root@$vsphere_ip "esxcli vm process kill --type=soft --world-id=$VM_WORLD_ID_1"
		rsh root@$vsphere_ip "esxcli vm process kill --type=soft --world-id=$VM_WORLD_ID_2"
	fi
	
	#Change or Add CPU shares on .vmx file	
	CPU_SHARES_1=$((($p1 * $TOTAL_SHARES)/100))
	CPU_SHARES_2=$((($p2 * $TOTAL_SHARES)/100))

	if [ "$(rsh root@$vsphere_ip grep sched.cpu.shares $vm1_config_file)x" = "x" ]; then 
		echo -e "sched.cpu.shares = \"$CPU_SHARES_1\"" | ssh root@$vsphere_ip "cat >> $vm1_config_file";		
	else rsh root@$vsphere_ip "sed -i 's/sched.cpu.shares.*/sched.cpu.shares = \"$CPU_SHARES_1\"/g' $vm1_config_file;" 
	fi

	if [ "$(rsh root@$vsphere_ip grep sched.cpu.shares $vm2_config_file)x" = "x" ]; then 
		echo -e "sched.cpu.shares = \"$CPU_SHARES_2\"" | ssh root@$vsphere_ip "cat >> $vm2_config_file";		
	else rsh root@$vsphere_ip "sed -i 's/sched.cpu.shares.*/sched.cpu.shares = \"$CPU_SHARES_2\"/g' $vm2_config_file;" 
	fi

	rsh root@$vsphere_ip "vim-cmd vmsvc/reload $VM_ID_1"
	rsh root@$vsphere_ip "vim-cmd vmsvc/reload $VM_ID_2"
	rsh root@$vsphere_ip "vim-cmd vmsvc/power.on $VM_ID_1"
	rsh root@$vsphere_ip "vim-cmd vmsvc/power.on $VM_ID_2"
	sleep 25
}

function restrict_disk
{
	p1=$1
	p2=$2
	TOTAL_SHARES=2000

	#Get identification	
	rsh root@$vsphere_ip esxcli vm process list | grep -B1 World | sed 's/^ *W.* //g' | grep -v "-" > /tmp/vm_name_worldID_alloc
	VM_WORLD_ID_1=$(head -2 /tmp/vm_name_worldID_alloc | tail -1)
	VM_WORLD_ID_2=$(head -4 /tmp/vm_name_worldID_alloc | tail -1)
	
	#Turn Off VMs if they are powered on
	if [ -s "/tmp/vm_name_worldID_alloc" ]; then		
		rsh root@$vsphere_ip "esxcli vm process kill --type=soft --world-id=$VM_WORLD_ID_1"
		rsh root@$vsphere_ip "esxcli vm process kill --type=soft --world-id=$VM_WORLD_ID_2"
	fi
	
	#Change or Add DISK shares on .vmx file	
	DISK_SHARES_1=$((($p1 * $TOTAL_SHARES)/100))
	DISK_SHARES_2=$((($p2 * $TOTAL_SHARES)/100))

	if [ "$(rsh root@$vsphere_ip grep sched.scsi0:0.shares $vm1_config_file)x" = "x" ]; then 
		echo -e "sched.scsi0:0.shares = \"$DISK_SHARES_1\"" | ssh root@$vsphere_ip "cat >> $vm1_config_file";		
	else rsh root@$vsphere_ip "sed -i 's/sched.scsi\(.[^.]*\)\.shares.*/sched.scsi\1\.shares = \"$DISK_SHARES_1\"/g' $vm1_config_file;"
	fi

	if [ "$(rsh root@$vsphere_ip grep sched.scsi0:0.shares $vm2_config_file)x" = "x" ]; then 
		echo -e "sched.scsi0:0.shares = \"$DISK_SHARES_2\"" | ssh root@$vsphere_ip "cat >> $vm2_config_file";		
	else rsh root@$vsphere_ip "sed -i 's/sched.scsi\(.[^.]*\)\.shares.*/sched.scsi\1\.shares = \"$DISK_SHARES_2\"/g' $vm2_config_file;"
	fi

	rsh root@$vsphere_ip "vim-cmd vmsvc/reload $VM_ID_1"
	rsh root@$vsphere_ip "vim-cmd vmsvc/reload $VM_ID_2"
	rsh root@$vsphere_ip "vim-cmd vmsvc/power.on $VM_ID_1"
	rsh root@$vsphere_ip "vim-cmd vmsvc/power.on $VM_ID_2"
	sleep 25
}

function unrestrict_cpu_cpuset
{
	
	#Get identification	
	rsh root@$vsphere_ip esxcli vm process list | grep -B1 World | sed 's/^ *W.* //g' | grep -v "-" > /tmp/vm_name_worldID_alloc
	VM_WORLD_ID_1=$(head -2 /tmp/vm_name_worldID_alloc | tail -1)
	VM_WORLD_ID_2=$(head -4 /tmp/vm_name_worldID_alloc | tail -1)
	
	echo $TOTAL_CORES | ssh $base_host_ip "cat > /tmp/alloc_cpu"
	echo $TOTAL_CORES | ssh $stress_host_ip "cat > /tmp/alloc_cpu"

	#Turn Off VMs if they are powered on
	if [ -s "/tmp/vm_name_worldID_alloc" ]; then		
		rsh root@$vsphere_ip "esxcli vm process kill --type=soft --world-id=$VM_WORLD_ID_1"
		rsh root@$vsphere_ip "esxcli vm process kill --type=soft --world-id=$VM_WORLD_ID_2"
	fi
	
	rsh root@$vsphere_ip "sed -i 's/sched.cpu.affinity.*//g' $vm1_config_file;"
	rsh root@$vsphere_ip "sed -i 's/sched.cpu.affinity.*//g' $vm2_config_file;"

	rsh root@$vsphere_ip "vim-cmd vmsvc/reload $VM_ID_1"
	rsh root@$vsphere_ip "vim-cmd vmsvc/reload $VM_ID_2"
	rsh root@$vsphere_ip "vim-cmd vmsvc/power.on $VM_ID_1"
	rsh root@$vsphere_ip "vim-cmd vmsvc/power.on $VM_ID_2"
	sleep 25
}

function restrict_cpu_cpuset
{
	#Get identification	
	rsh root@$vsphere_ip esxcli vm process list | grep -B1 World | sed 's/^ *W.* //g' | grep -v "-" > /tmp/vm_name_worldID_alloc
	VM_WORLD_ID_1=$(head -2 /tmp/vm_name_worldID_alloc | tail -1)
	VM_WORLD_ID_2=$(head -4 /tmp/vm_name_worldID_alloc | tail -1)

	echo $HALF_TOTAL_CORES | ssh $base_host_ip "cat > /tmp/alloc_cpu"
	echo $HALF_TOTAL_CORES | ssh $stress_host_ip "cat > /tmp/alloc_cpu"

	#Turn Off VMs if they are powered on
	if [ -s "/tmp/vm_name_worldID_alloc" ]; then		
		rsh root@$vsphere_ip "esxcli vm process kill --type=soft --world-id=$VM_WORLD_ID_1"
		rsh root@$vsphere_ip "esxcli vm process kill --type=soft --world-id=$VM_WORLD_ID_2"
	fi

	#restict CPU cores per VM	
	CPU_CORES_1=''
	CPU_CORES_2=''
	
	for (( i=0; i<$TOTAL_CORES; i++ )); do
    		if [ $((i%2)) -eq 0 ];
		then
    			CPU_CORES_1=$(echo ${CPU_CORES_1},${i});
		else
    			CPU_CORES_2=$(echo ${CPU_CORES_2},${i});
		fi
	done

	CPU_CORES_1=$(echo ${CPU_CORES_1:1})
	CPU_CORES_2=$(echo ${CPU_CORES_2:1})
	
	if [ "$(rsh root@$vsphere_ip grep sched.cpu.affinity $vm1_config_file)x" = "x" ]; then 
		echo -e "sched.cpu.affinity = \"$CPU_CORES_1\"" | ssh root@$vsphere_ip "cat >> $vm1_config_file";		
	else rsh root@$vsphere_ip "sed -i 's/sched.cpu.affinity.*/sched.cpu.affinity = \"$CPU_CORES_1\"/g' $vm1_config_file;" 
	fi

	if [ "$(rsh root@$vsphere_ip 	grep sched.cpu.affinity $vm2_config_file)x" = "x" ]; then 
		echo -e "sched.cpu.affinity = \"$CPU_CORES_2\"" | ssh root@$vsphere_ip "cat >> $vm2_config_file";		
	else rsh root@$vsphere_ip "sed -i 's/sched.cpu.affinity.*/sched.cpu.affinity = \"$CPU_CORES_2\"/g' $vm2_config_file;" 
	fi

	rsh root@$vsphere_ip "vim-cmd vmsvc/reload $VM_ID_1"
	rsh root@$vsphere_ip "vim-cmd vmsvc/reload $VM_ID_2"
	rsh root@$vsphere_ip "vim-cmd vmsvc/power.on $VM_ID_1"
	rsh root@$vsphere_ip "vim-cmd vmsvc/power.on $VM_ID_2"
	sleep 25
}
