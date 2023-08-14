#See also https://github.com/dnhsoft/sysinfo/blob/master/sysinfo.sh

echo "Starting lldpd so its ready for later"
sudo systemctl start lldpd

echo Manufacturer: " " $(sudo dmidecode | grep -A3 '^System Information' | grep Manufacturer)

#echo Total RAM available: $(free -h | gawk  '/Mem:/{print $2}') #Old incorrect
echo Total RAM available: " " $(sudo dmidecode -t memory | grep -P '(?<!Volatile )Size:\s\d+\s\w+' | grep -Po '(\d+)' | uniq -c | awk '{print v+=$1*$2}')

#This works but relies on omreport so cant use it, need to find another way to get the total number of slots available
#echo Used RAM slots: $(sudo /opt/dell/srvadmin/sbin/omreport chassis memory | grep "Slots Used\s*:" | grep -Po "\d*$") / $(sudo /opt/dell/srvadmin/sbin/omreport chassis memory | grep "Slots Available\s*:.*" | grep -Po "\d*$")

#Memory type with count of most common type, (doesnt seem to work anymore)
#sudo lshw -short -C memory | awk 'NR>2{for(i=3; i<=NF; ++i) printf "%s ", ; print ""}' | sort | uniq -c | sort | head -n 1
# 12 32GiB DIMM DDR4 Synchronous Registered (Buffered) 3200 MHz (0.3 ns)

#echo Used RAM slots: " " $(sudo dmidecode -t memory | grep -c -Po '^\tPart Number: (?!\[Empty\])') / $(sudo lshw -class memory | awk '/bank/ {count++} END {print count}')

echo Used RAM slots: " " $(sudo dmidecode -t memory | grep "Serial" | tr -d " " | cut -d ":" -f 2 | grep -vc "NotSpecified") / $(sudo dmidecode -t memory | grep Devices | tr -d ' ' | cut -d ':' -f2)

echo Total CPU Cores: $(cat /proc/cpuinfo  | grep process| wc -l)  #try "grep -c process" instead of wc -l?
#Another way to do this is #cat /proc/cpuinfo | grep '^model name' | cut -d: -f 2- | sort | uniq -c

echo $(lscpu | grep "Thread(s) per core")

#echo old echo PSU: $(sudo lshw -c power | grep -i 'description' --count) x $(sudo lshw -c power | grep -oP '(?<=description: ).*' | sort --unique)
#echo PSU: $(sudo dmidecode --type 39 | grep -i 'Name' --count) x $(sudo dmidecode --type 39 | grep -oP '(?<=Name: ).*' | sort --unique)
psuinfo=$(sudo dmidecode --type 39 | grep -i 'Name' --count) " x " $(sudo dmidecode --type 39 | grep -oP '(?<=Name: ).*' | sort --unique)
if [[ -z "$psuinfo" ]]; then psuinfo="blank"; fi
echo PSU: $psuinfo



#echo ConnectX5: $(sudo lspci | grep -oP '(?<=Ethernet controller: ).*' | uniq | grep -i "Mellanox")
connectx5info=$(sudo lspci | grep -oP '(?<=Ethernet controller: ).*' | uniq | grep -i "Mellanox")
if [[ -z "$connectx5info" ]]; then connectx5info="blank"; fi
echo ConnectX5: $connectx5info


#echo
#echo ConnectX attempt2: $(cut -f1,2,18 /proc/bus/pci/devices | grep "15b3" | awk 'BEGIN { printf "ConnectX:" }; END { ORS=" " }; {printf $2 " " $3 ";"}')
#echo

#portinfo=$(sudo lldpcli show nei)
#echo Port info: "$portinfo"

#echo "Partition layout"
#partitioninfo=$(df -h | grep "/dev/" | tr -s " " | cut -d " " -f 1,2,6 | sort)
#echo "$partitioninfo"
echo
echo partition_layout.txt
#omreport usage https://www.dell.com/support/manuals/en-au/openmanage-server-administrator-v9.3.2/om_9.3.2_command_line_interface/omreport-chassis-info-or-omreport-mainsystem-info
#omreport usage more https://dl.dell.com/topicspdf/openmanage-server-administrator-v93_cli-guide_en-us.pdf


echo Boot: " " $(timeout 10s bash -c sudo /opt/dell/srvadmin/sbin/omreport chassis biossetup | grep "^Boot Mode" | grep -Po "(?<=\:).*")
#Alternative way
#For UEFI,  if you can see /boot/efi partition with df -h command.
#echo UEFI:  " " $(sudo df -h | grep -o /boot/efi)  #works but there is a better way
echo UEFI:  " " $([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)

#echo $(sudo /opt/dell/srvadmin/sbin/omreport chassis biossetup | grep "Set Boot Order Enable")
echo vg name:  " " - $(sudo vgs --noheadings -o vg_name | tr -d '  ')
echo

#sudo lsblk -l | grep '/boot$\|/var$\|-root' | gawk '{print , }'
echo physical name boot:  " "  - $(sudo lsblk -l | grep '\/boot$' | gawk '{print $NF, $4}') 
echo 
echo lvm name root:  " " - $(sudo lsblk -l | grep '\/root$' | gawk '{print $NF, $4}') 
echo lvm name var:  " " - $(sudo lsblk -l | grep '\/var$' | gawk '{print $NF, $4}') 

echo VGSizes:  " " $(sudo lvs vg00 --noheadings | awk '{print "/",$1 , $NF}' | sed 's/\.00g$/G/g')

echo
echo compute.txt
echo Chassis:  " " $(sudo /opt/dell/srvadmin/sbin/omreport chassis info | grep "Chassis Model" | grep -Po "(?<=\:).*")
echo Product Name: " " $(sudo dmidecode | grep -A3 '^System Information' | grep "Product Name" | grep -Po "(?<=\:).*")
echo BOSS:  " " $(/opt/dell/srvadmin/sbin/omreport system version | grep -i "boss" | grep -Po "(?<=\:).*")
echo Processor: " " $(cat /proc/cpuinfo  | grep -Po "(?<=model name.:)(.*)" | uniq)
#Another way to get processors # sudo /opt/dell/srvadmin/sbin/omreport chassis processors



#echo HDDs: $(sudo lshw -class disk | grep -c "*-disk")
#look for mdadm as well?
echo HDDs:  " " $(sudo ls /dev/sd*[a-z] | wc -w)

#echo HDD $(sudo lshw -class disk | grep "size:") #size
#echo HDD sizes:  " " $(lsblk -n | grep -P disk | awk 'BEGIN { printf "HDD Sizes:" }; END { ORS=" " }; { printf " " $1  " " $4 ";"}') #HDD sizes
echo HDD sizes:  " " $(lsblk -n | grep -P disk | grep sd | awk '{ printf $4 "\n"}' | uniq) #HDD sizes excluding nvme


echo SAS HDD Count: " " $(lsblk -O | grep -Poc "ST180")	
echo SAS HDD type: " " $(lsblk -O | grep -P "ST180" | grep -Po "\d+\.*\d+T" | uniq)


echo RAID Type:  " " $(omreport storage vdisk | grep -P "^Layout\s+:") 
echo RAID Status:  " " $(omreport storage vdisk | grep -P "^Status\s+:") 




#echo NVME: $(sudo lshw -short | grep -oP '(?<=/dev/nvme.       storage        ).*'  | uniq -c)
#echo NVME names:  " " $(lsblk | grep nvme | awk '{print $1 " "$4";"}')
echo NVME count:  " " $(lsblk | grep -c "nvme")
echo NVME sizes:  " " $(lsblk | grep nvme | awk '{print $4;}' | uniq)


#Root disk
echo Root Disk: " " $(findmnt -n | grep -P "^/\s+" | grep -P "([^\/]+)(?=ext4)")




#To get info from IDRAC: sudo /opt/dell/srvadmin/sbin/omreport  storage pdisk controller=0
echo LCD Bezel: " " $(/opt/dell/srvadmin/sbin/omreport chassis frontpanel | grep "View and Modify")


#Get number of Fans

fancheck=16
i=0
while [[ $i -ne $fancheck ]]
do
	if eval sudo /opt/dell/srvadmin/sbin/omreport chassis fans index=$i > /dev/null; then
       success=$((success+1))
	else 
	    failure=$((failure+1))
   fi
i=$(($i+1))
done

echo Fans present: " " $success


echo
echo Cabling data
echo


e1p1info=$(sudo lldpcli show nei -f keyvalue | grep -P "lldp.e1p1.chassis.name=|lldp.e1p1.port.ifname")
p1p1info=$(sudo lldpcli show nei -f keyvalue | grep -P "lldp.p1p1.chassis.name=|lldp.p1p1.port.ifname")
p1p2info=$(sudo lldpcli show nei -f keyvalue | grep -P "lldp.p1p2.chassis.name=|lldp.p1p2.port.ifname")
allcablinginfo=$(sudo lldpcli show nei -f keyvalue | grep -P "lldp.[^\.]*.chassis.name=|lldp.[^\.]*.port.ifname") 
 
#Check for empty values
if [[ -z "$e1p1info" ]]; then e1p1info="blank"; fi
if [[ -z "$p1p1info" ]]; then p1p1info="blank"; fi
if [[ -z "$p1p2info" ]]; then p1p2info="blank"; fi
if [[ -z "$allcablinginfo" ]]; then allcablinginfo="blank"; fi

echo SwitchPort info
echo e1p1info: " " $e1p1info
echo p1p1info: " " $p1p1info
echo p1p2info: " " $p1p2info
echo allcablinginfo: " " $allcablinginfo


#Another way to get NICs #echo $(sudo /opt/dell/srvadmin/sbin/omreport chassis nics)

echo
echo Additional info
echo ServiceTag: " " $(sudo dmidecode -s system-serial-number)
echo IP addresses: " " $(hostname -I)

#echo Operating system: $(lsb_release -d)
echo Operating system: " " $(if [[ -f /etc/lsb-release ]]; then lsb_release -d; else cat /etc/redhat-release; fi )


echo Kernel: " " $(uname -a)
macadresses=$(sudo lldpcli show nei -f keyvalue | grep "lldp.[^\.]*.chassis.mac=") 
#echo MAC addresses: $macadresses idrac.mac=$(sudo /opt/dell/srvadmin/sbin/omreport chassis remoteaccess | grep "MAC Address" )
echo MAC addresses: " " $macadresses idrac.mac=$(sudo /opt/dell/srvadmin/sbin/omreport chassis remoteaccess | grep -Po "([0-9A-Fa-f]{2}[-]){5}([0-9A-Fa-f]{2})" )

echo GPU info: " " $(sudo lspci | grep ' VGA ' | cut -d" " -f 1 | xargs -i lspci -v -s {} | xargs)

#Get name of switch that the host is pluged into (requires MAC address to be passed as an argument) 
echo MAC1g info: " " $(sudo lldpcli show neigh | grep -A 3 $(ip link show | grep -B1 -i $mac1g | awk -F': ' '{print $2}') | grep -Po "(?<=SysName:\s)(.*)" | cut -f1 -d"." | tr -d "[:blank:]")

#Get switch port that the host is pluged into (requires MAC address to be passed as an argument)
echo MAC1g swp: " " $(sudo lldpcli show neigh | grep -A 11 $(ip link show | grep -B1 -i $mac1g | awk -F': ' '{print $2}') | grep -Po "(?<=PortDescr:\s)(.*)" | tr -d "[:blank:]")

#Get name of switch that the host is pluged into (requires MAC address to be passed as an argument) 
echo MACiDRAC info: " " $(sudo lldpcli show neigh | grep -A 3 $(ip link show | grep -B1 -i $macidrac | awk -F': ' '{print $2}') | grep -Po "(?<=SysName:\s)(.*)" | cut -f1 -d"." | tr -d "[:blank:]")

#Get switch port that the host is pluged into (requires MAC address to be passed as an argument)
echo MACiDRAC swp: " " $(sudo lldpcli show neigh | grep -A 11 $(ip link show | grep -B1 -i $macidrac | awk -F': ' '{print $2}') | grep -Po "(?<=PortDescr:\s)(.*)" | tr -d "[:blank:]")

echo All HDDs: " " $(printf "%sx%s\n" $(lsblk | grep "disk" | grep -Po "\d+\.\d+(T|G)" | uniq -c | sort -nk2) | xargs)

#echo Nvidia: " " $(sudo lspci | grep -i 'nvidia' | cut -d" " -f 1 | xargs -i lspci -v -s {} | xargs)
echo Nvidia: " " $(sudo lspci -nn | grep -i "nvidia")

echo done on the host
