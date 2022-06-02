#!/bin/bash
#
#------------------------------
#
# manageODMclusterWAS9.sh <cmd> [server] 
#  usge: run, manageODMclusterWAS9
# --------------------------------
#
export ver
if   [ $HOSTNAME == "odm1" ] ;  then   ver="8110"
elif [ $HOSTNAME == "odm"  ] ;  then   ver="81051" ; fi

# paths 
export WAS_HOME=/opt/IBM/WAS9/AppServer
export ODM_HOME=/opt/IBM/ODM$ver
export WAS_PROFILE=$WAS_HOME/profiles
export WAS_DMGR01=$WAS_PROFILE/Dmgr01
export WAS_NODE01=$WAS_PROFILE/ODMMachine01
export dmgr_bin=$WAS_DMGR01/bin
export node_bin=$WAS_NODE01/bin
statusLoc=/tmp/.srvStatus

# cmds 
dmgrStartServer=$dmgr_bin/startServer.sh 
dmgrStopServer=$dmgr_bin/stopServer.sh
nodeStartServer=$node_bin/startServer.sh
nodeStopServer=$node_bin/stopServer.sh
dmgrServerStatus=$dmgr_bin/serverStatus.sh
nodeServerStatus=$node_bin/serverStatus.sh
srvStatus="cat $statusLoc"

# vars/ constants 
export dmgr="dmgr"
export node="nodeagent"
export dc="Node01-DCServer"
export ds="Node01-DSServer"
export res="RulesMgrSrv"
creds="-username admin -password admin " 
NULL=/dev/null
force=""     

#-----------------------

function startServer()
{
    Dmgr=$(echo $1 | grep dmgr )
    if [[ $Dmgr ]]  ; then
      cmd1=$dmgrServerStatus
      cmd2=$dmgrStartServer
    else
      cmd1=$nodeServerStatus
      cmd2=$nodeStartServer
    fi
 
    if [ -n "$force" ] ; then
     echo "Starting $1 server ..."   
      $cmd2 $1 $creds &> $NULL 2>&1
      echo "$1 server started."
    else
     $cmd1 $1 $creds  &> $statusLoc 2>&1
     if $srvStatus | grep -w STARTED > $NULL ; then
      echo "$1 already started"
     elif $srvStatus | grep -w stopped > $NULL ; then
      echo "Starting $1 server  ..." 
      $cmd2 $1 $creds  &> $NULL 2>&1 
      echo "$1 server started."
     else
      echo "$1 status unknown"
      echo "logout or reboot and try again"
     fi
    fi
}

function stopServer()
{
    Dmgr=$(echo $1 | grep dmgr )
    if [[ $Dmgr ]]  ; then
      cmd1=$dmgrServerStatus
      cmd2=$dmgrStopServer
    else
      cmd1=$nodeServerStatus
      cmd2=$nodeStopServer
    fi

   if [ -n  "$force"  ] ; then
     echo "Stopping $1 server ..." 
     $cmd2 $1 $creds  &> $NULL 2>&1
     echo "$1 server stopped" 
   else
    $cmd1 $1 $creds  &> $statusLoc 2>&1
    if $srvStatus | grep -w STARTED > $NULL ; then
      echo "Stopping server $1 ..."  
      $cmd2 $1 $creds &> $NULL 2>&1
      echo "$1 server stopped"
    elif $srvStatus | grep -w stopped > $NULL ; then
      echo "$1 already stopped"
    else
      echo "$1 status unknown"
      echo "logout or reboot and try again"
    fi
   fi
}

function serverStatus()
{
    Dmgr=$(echo $1 | grep dmgr )
    if [[ $Dmgr ]]  ; then
      cmd=$dmgrServerStatus
    else
      cmd=$nodeServerStatus
    fi

     $cmd $1 $creds   > $statusLoc
     if $srvStatus | grep -w STARTED > $NULL ; then
      status="STARTED"
     elif $srvStatus | grep -w stopped > $NULL ; then
      status="STOPPED"
     else
      status="STATUS UNKNOWN"
    fi
    echo "$1 is $status"
}

function startCluster()
{
  if [[ ! "$server" ]] ; then
   echo "Starting cluster, please wait ..."
   declare -a cluster=( $dmgr $node $dc $ds $res )
   for server in ${cluster[@]}; do
     startServer  $server
   done
   echo "Cluster started."
   unset server 
   displayInfo.sh 
 else
  force=true
  startServer $server
  if [[ "$server" == "RulesMgrSrv" ]] ; then
   echo "ODM RES URL:  https://$HOSTNAME:9444/res/login.jsf"
  elif  [[ "$server" == "Node01-DCServer" ]] ; then
   echo "ODM DC URL:   https://$HOSTNAME:9445/decisioncenter"
  fi
 fi
}

function stopCluster()
{
 if [[ ! "$server" ]] ; then
  echo "Stopping cluster, please wait ..."
  declare -a cluster=( $res $ds $dc $node $dmgr )
  for server in ${cluster[@]}; do
    stopServer $server
  done
  echo "Cluster stopped."
  unset server
 else
  force=true
  stopServer $server 
 fi
}

function clusterStatus()
{
 if [[ ! "$server" ]] ; then
  echo "Getting cluster status ..."
  declare -a cluster=( $dc $res $ds $node $dmgr )
  for server in ${cluster[@]}; do
    serverStatus $server
  done
 else
   echo "Getting $server status ..." 
   serverStatus $server
 fi
}


#--------- main --------------
#
# shopt -s nullglob
# if [ ! $WAS_NODE01/* ]; then
#   echo "Cluster does not exist, run createODMclusterWAS9.sh to create cluster"
#   exit
# fi

if [[ $2 ]] ; then
 case $2 in
   dmgr) server=$dmgr ;;
   node) server=$node ;;
   dc)   server=$dc ;;
   ds)   server=$ds ;;
   res)  server=$res ;;
   *)
      echo "$2 not found in cluster"
      echo "choose from: dmgr,node,dc,ds,res"
      echo "or leave blank for all servers in cluster"
      exit ;;
  esac
fi

# force executes action overriding status
if [[ $3 == "force" ]]; then force=true ; fi 
 
case $1 in
    start)   startCluster ;; 
    stop)    stopCluster ;;   
    restart) stopCluster ; startCluster ;; 
    status)  clusterStatus ;;
    info)    displayInfo.sh ;;
    help)    displayInfo.sh cmd ; exit  ;;
    *)       displayInfo.sh cmd ; exit  ;;  
esac
