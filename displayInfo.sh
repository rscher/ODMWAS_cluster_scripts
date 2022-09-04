#!/bin/bash
#
# displayInfo.sh [$1] 
#
#  where optional $1=[cmd, urls, logs, wlp]
#  when one of the arg1 values entered, displayInfo
#  will display the info corresponding to arg1
#  otherwise all info is displayed , by default.
#
#--------------------------------
# Node1: local servers 
# ODMMachine01 profile
export dmgr="dmgr"
export node1="nodeagent"
export dc1="Node01-DCServer"
export ds1="Node01-DSServer"
export res="RulesMgrSrv"

# Node2: remote servers
# ODMMachine01 profile
export node2="nodeagent"
export dc2="Node02-DCServer"
export ds2="Node02-DSServer"

function display_info()
{

if   [ $HOSTNAME == "odm1" ] ;  then   remoteNodeHostName="odm"
elif [ $HOSTNAME == "odm"  ] ;  then   remoteNodeHostName="odm1" ; fi

hostName=$(hostname -f)
IPaddr=$(hostname -i)
remoteHostFQDN=$(ssh $remoteNodeHostName hostname -f)
remoteHostIPaddr=$(ssh $remoteNodeHostName hostname -i)

echo "Cell/dmgr Node1 hostname: $hostName  IPaddr: $IPaddr"
echo "   remote Node2 hostname:  $remoteHostFQDN  IPaddr: $remoteHostIPaddr"

declare -a cluster=( $dc1 $ds1 $res $node1 $dmgr )
 echo "cluster contains local servers:"
 for server in ${cluster[@]}; do
   echo " $server"
 done
echo ""

declare -a cluster1=( $dc2 $ds2 $node2)
 echo "cluster contains remote servers on hostname: $remoteNodeHostName"
 for server in ${cluster1[@]}; do
   echo " $server"
 done
 echo ""
}

function display_cmd()
{
#  echo "-- ODM$ver WAS9 ND cluster cmds --"
 echo "Usage: manageODMclusterWAS9 arg1 [arg2]"
 echo "" 
 echo "arg1: cluster-scoped cmds <startDS, stopDS, startDC, stopDC>"
 echo "      *most commonly used "
 echo "      cluster-wide cmds <start,stop,restart,status, info, help>"
 echo ""
 echo "arg2: server-scoped cmds <dc1,dc2,ds1,ds2,res,node1,node2,dmgr>"
 echo "     *limits the scope of cluster-wide cmds to a specified server"
 echo "      useful for starting/stopping nodeagent on node1 or node2"
 echo "      or getting status for a specific server"
 echo ""
 echo "examples:"
 echo "'manageODMclusterWAS9 startDS'     starts DS cluster on Node01 and Node02"
 echo "'manageODMclusterWAS9 start'       start all servers (entire cluster) on both nodes"
 echo "'manageODMclusterWAS9 status'      displays status of all servers (entire cluster)"
 echo "'manageODMclusterWAS9 stop dc1'    stops DC server on Node01"
 echo "'manageODMclusterWAS9 start node2' starts nodeagent on Node02"
 echo "'manageODMclusterWAS9 status ds2 ' displays status of DS on Node02"
 echo ""
 echo "run 'manageODMclusterWAS9 info' for detailed cluster info and cmd options"
}

function display_urls()
{
echo "--ODM$ver WAS9 Server URLs--"
echo "ODM DC:      https://$HOSTNAME:9445/decisioncenter"
echo "ODM DC-API:  https://$HOSTNAME:9445/decisioncenter-api/swagger-ui.html"
echo "ODM RES:     https://$HOSTNAME:9444/res/login.jsf"
echo "ODM DR:      https://$HOSTNAME:9443/DecisionRunner"
echo "WAS Admin:   https://$HOSTNAME:9043/ibm/console"
echo "               user/pw: admin/admin"
echo ""
}

function display_logs()
{
echo "--To view ODM$ver WAS9 ND local server logs--"
echo "DC1,   run: tail"$ver"WAS9dc1"
echo "DC2,   run: tail"$ver"WAS9dc2"
echo "DS1,   run: tail"$ver"WAS9ds1"
echo "DS2,   run: tail"$ver"WAS9ds2"
echo "RES,   run: tail"$ver"WAS9res"
echo "Dmgr,  run: tailWAS9dmgr"
echo "Node1, run: tailWAS9node1"
echo "Node2, run: tailWAS9node2"
}

function display_cmd2()
{
# to be used in future ... 
#
# echo "more info ..."
 cmd2=""
}

function display_wlp()
{
 echo "_______________________________________________"
 echo ""
 echo "--ODM 81051 Liberty sample server cmds:  "
 echo "     start81051, stop81051, restart81051, tail81051 "
 echo "_______________________________________________"
}

function display_all()
{
 echo ""
  declare -a disp=( info cmd cmd2 urls logs )
  for section in ${disp[@]}; do
    display_$section
  done
 echo "_______________________________________________"
 echo "To view this info anytime, run cmd: displayInfo"
}


#
# ------------- Main -----------
# 
if [[ ! $1 = @("cmd"|"cmd2"|"info"|"urls"|"logs"|"wlp"|"") ]]; then 
  echo "$1 not valid, options are: cmd, cmd2, info, urls, logs, wlp"
  exit
elif [ -n "$1" ] ; then  display_$1
else display_all 
fi
#
# ----------------------------
