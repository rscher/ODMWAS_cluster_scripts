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
export dmgr="dmgr"
export node="nodeagent"
export dc="Node01-DCServer"
export ds="Node01-DSServer"
export res="RulesMgrSrv"

# Node2: remote servers
export node2="nodeagent"
export dc2="Node02-DCServer"
export ds2="Node02-DSServer"

function display_info()
{
hostName=$(hostname -f) 
IPaddr=$(hostname -i)

if   [ $HOSTNAME == "odm1" ] ;  then   remoteNodeHostName="odm"
elif [ $HOSTNAME == "odm"  ] ;  then   remoteNodeHostName="odm1" ; fi
echo "Cell/dmgr Node01 hostname: $hostName  IPaddr: $IPaddr"

declare -a cluster=( $dc $ds $res $node $dmgr )
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
echo "-- ODM$ver WAS9 ND cluster cmds --"
 echo "Usage: manageODMclusterWAS9 arg1 [arg2]"
 echo "arg1=action <start,stop,restart,status, info, help>"
 echo "arg2=server <dc,res,ds,dmgr,node>"
 echo " if arg2 entered,action is taken on specified server"
 echo " otherwise action applies to all servers in cluster"
 echo "examples:"
 echo "'manageODMclusterWAS9 restart' will restart entire cluster"
 echo "'manageODMclusterWAS9 restart dc' will restart DCServer only "
echo ""
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
echo "DC,  run: tail"$ver"WAS9dc"
echo "DS,  run: tail"$ver"WAS9ds"
echo "RES, run: tail"$ver"WAS9res"
echo "Dmgr,run: tailWAS9dmgr"
echo "Node,run: tailWAS9node"
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
