#!/bin/bash
#                       
#------------------------------
#
# manageODMclusterWAS9.sh <cmd> [server] 
#  usage: run: manageODMclusterWAS9
#  
# Desc: utility script to manage 2-node cluster
#  built from  createODMclusterWAS9.sh script
#  for castle lib: ODM 8.10.5.1 and ODM 8.11.0.1 Prod Cluster
#   
#  v1.0: 9/3/22  initial working version 
# -------------------------------------------------
#
# --- variables ---
# uncomment debug to enable cmd logging
# debug=true
creds="-username admin -password admin"
statusLoc=/tmp/.srvStatus
srvStatus="cat $statusLoc"
NULL=/dev/null
force=""
export ver
export remoteNodeHostName

# --- server paths --- 
export WAS_HOME=/opt/IBM/WAS9/AppServer
export WAS_PROFILE=$WAS_HOME/profiles
export WAS_DMGR=$WAS_PROFILE/Dmgr01
export WAS_NODE1=$WAS_PROFILE/ODMMachine01
export WAS_NODE2=$WAS_PROFILE/ODMMachine02
export dmgr1_bin=$WAS_DMGR/bin
export node1_bin=$WAS_NODE1/bin
export node2_bin=$WAS_NODE2/bin
export usrLocal_bin=/usr/local/bin

# --- cluster paths ---
export startDSclusterPy=$usrLocal_bin/startDScluster.py
export stopDSclusterPy=$usrLocal_bin/stopDScluster.py
export startDCclusterPy=$usrLocal_bin/startDCcluster.py
export stopDCclusterPy=$usrLocal_bin/stopDCcluster.py

# --- server cmds --- 
dmgr_wsadmin=$dmgr1_bin/wsadmin.sh
dmgrStartServer=$dmgr1_bin/startServer.sh 
dmgrStopServer=$dmgr1_bin/stopServer.sh
dmgrServerStatus=$dmgr1_bin/serverStatus.sh
node1StartServer=$node1_bin/startServer.sh
node1StopServer=$node1_bin/stopServer.sh
node1ServerStatus=$node1_bin/serverStatus.sh
node2StartServer=$node2_bin/startServer.sh
node2StopServer=$node2_bin/stopServer.sh
node2ServerStatus=$node2_bin/serverStatus.sh
ldapServerStatus="/opt/apacheds-2.0.0.AM25/bin/apacheds status default"

# --- cluster cmds ---
export startDScluster="$dmgr_wsadmin -lang jython $creds -f $startDSclusterPy"
export stopDScluster="$dmgr_wsadmin  -lang jython $creds -f $stopDSclusterPy"
export startDCcluster="$dmgr_wsadmin -lang jython $creds -f $startDCclusterPy"
export stopDCcluster="$dmgr_wsadmin  -lang jython $creds -f $stopDCclusterPy"

# --- server name lookup ---
export dmgr="dmgr"
export node1="nodeagent"
export dc1="Node01-DCServer"
export ds1="Node01-DSServer"
export res="RulesMgrSrv"
export node2="Node02-nodeagent"
export dc2="Node02-DCServer"
export ds2="Node02-DSServer"

# --- hosts info --- 
if   [ $HOSTNAME == "odm1" ] ; then remoteNodeHostName="odm"
elif [ $HOSTNAME == "odm"  ] ; then remoteNodeHostName="odm1" ; fi
export LDAPhostname="odm"

#-----------------------

function startServer()
{
    server=$1
    msg=""
    if [[ $(echo $1 | grep dmgr ) ]]  ; then
      cmd1=$dmgrServerStatus
      cmd2=$dmgrStartServer
    elif [[ $(echo $1 | grep Node02 ) ]]  ; then 
      nodeAgent=$(echo $1 | grep nodeagent )
      if [[ $nodeAgent ]]  ; then  
         server="nodeagent"    
      fi 
      cmd1="ssh $remoteNodeHostName $node2ServerStatus"
      cmd2="ssh $remoteNodeHostName $node2StartServer"
      msg="on Node02 on remote host: $remoteNodeHostName"
    else
      cmd1=$node1ServerStatus
      cmd2=$node1StartServer
      msg="on Node01 on local host: $HOSTNAME"
    fi

    # ============  debug  ==============
     if [[ $debug ]] ; then 
       echo "debug cmd1: $cmd1 $server $creds"  
       echo "debug cmd2: $cmd2 $server $creds"
     fi

    if [ -n "$force" ] ; then
     echo "Starting $server $msg ..."   
     $cmd2  $server $creds &> $NULL 2>&1
     echo "$server started."
    else
     $cmd1  $server $creds  &> $statusLoc 2>&1
     if $srvStatus | grep -w STARTED > $NULL ; then
      echo "$server already started $msg"
     elif $srvStatus | grep -w stopped > $NULL ; then
      echo "Starting  $server  $msg..." 
      $cmd2  $server $creds  &> $NULL 2>&1 
      echo " $server started."
     else
      echo " $server status unknown"
      echo " restart $server and try again"
     fi
    fi
}

function stopServer()
{
    server=$1
    msg=""
    if [[ $(echo $1 | grep dmgr ) ]]  ; then
      cmd1=$dmgrServerStatus
      cmd2=$dmgrStopServer
    elif [[ $(echo $1 | grep Node02 ) ]]  ; then
      nodeAgent=$(echo $1 | grep nodeagent )
      if [[ $nodeAgent ]]  ; then
         server="nodeagent"
      fi
      cmd1="ssh $remoteNodeHostName $node2ServerStatus"
      cmd2="ssh $remoteNodeHostName $node2StopServer"
      msg="on Node02 on remote host: $remoteNodeHostName"
    else
      cmd1=$node1ServerStatus
      cmd2=$node1StopServer
      msg="on Node01 on localhost: $HOSTNAME"
    fi

    # ============  debug  ==============
     if [[ $debug ]] ; then
       echo "debug cmd1: $cmd1 $server $creds" 
       echo "debug cmd2: $cmd2 $server $creds"  
     fi

   if [ -n  "$force"  ] ; then
     echo "Stopping $server $msg ..." 
     $cmd2  $server  $creds  &> $NULL 2>&1
     echo " $server stopped" 
   else
    $cmd1  $server $creds  &> $statusLoc 2>&1
    if $srvStatus | grep -w STARTED > $NULL ; then
      echo "Stopping $server $msg  ..."  
      $cmd2  $server $creds &> $NULL 2>&1
      echo " $server stopped"
    elif $srvStatus | grep -w stopped > $NULL ; then
      echo "$server already stopped $msg"
    else
      echo "$server status unknown"
      echo "logout or reboot and try again"
    fi
   fi
}

function serverStatus()
{
    server=$1
    msg=""
    if [[ $(echo $1 | grep dmgr ) ]]  ; then
      cmd=$dmgrServerStatus
    elif [[ $(echo $1 | grep Node02 ) ]]  ; then
      nodeAgent=$(echo $1 | grep nodeagent )
      if [[ $nodeAgent ]]  ; then
         server="nodeagent"
      fi
      cmd="ssh $remoteNodeHostName $node2ServerStatus"
    else
      cmd=$node1ServerStatus
    fi
     # ============  debug  ==============
     if [[ $debug ]] ; then echo "debug cmd: $cmd $server $creds" ; fi

     $cmd $server $creds   > $statusLoc
     if $srvStatus | grep -w STARTED > $NULL ; then
      status="STARTED"
     elif $srvStatus | grep -w stopped > $NULL ; then
      status="STOPPED"
     else
      status="STATUS UNKNOWN"
    fi
    echo "$server is $status $msg"
}

function startCluster()
{
 if [[ ! "$server" ]] ; then
  echo "Starting all servers in cluster (node1 and node2)  ..."
  declare -a cluster=( $dmgr $node1 $node2 $dc1 $dc2 $ds1 $ds2 $res )
  for server in ${cluster[@]}; do
    startServer  $server   
  done
  echo "Cluster started." 
  unset server 
  displayInfo.sh 
 else
  force=true
  startServer $server
 fi
}

function stopCluster()
{
 if [[ ! "$server" ]] ; then
  echo "Stopping all servers in cluster (Node01 and Node02) ..."
  declare -a cluster=( $res $ds1 $ds2 $dc1 $dc2 $node1 $node2 $dmgr )
  for server in ${cluster[@]}; do
    stopServer $server 
  done
 else
  force=true
  stopServer $server 
 fi
}

function ldapDSStatus()
{
  echo "Apache LDAP DS status on hostname: $LDAPhostname"
  echo "---------------------------------------------"
  # get apache LDAP server status
  if [ $HOSTNAME != $LDAPhostname ] ; then
   cmd="ssh $LDAPhostname $ldapServerStatus"
  else
   cmd=$ldapServerStatus
  fi
  # ============  debug  ==============
  if [[ $debug ]] ; then echo "debug cmd: LDAP server status: $cmd " ; fi
  $cmd
}

function restartCluster()
{
 echo "Restarting all servers in cluster (node1 and node2) ..."
 stopCluster 
 startCluster 
}

function clusterStatus()
{
 if [[ ! "$server" ]] ; then
  echo "Status of Node01 local servers on hostname: $HOSTNAME" 
  echo "---------------------------------------------"
  declare -a cluster=( $dc1 $res $ds1 $node1 $dmgr )
  for server in ${cluster[@]}; do
    serverStatus $server
  done
  echo ""

  # get remote node2 status 
  echo "Status of Node02 remote servers on hostname: $remoteNodeHostName "
  echo "---------------------------------------------"
  declare -a cluster=( $dc2 $ds2 $node2 )
  for server in ${cluster[@]}; do
    serverStatus $server
  done
  echo ""
  # ldapDSStatus
 else
   # echo "Getting $server status ..." 
   serverStatus $server
 fi
}

#---------------------------------
# cluster cmds across both nodes

function startDScluster()
{
 echo "Issuing DS cluster start on Node01 and Node02 ..." 
 echo "may take awhile for all servers/applications to complete startup after cmd is issued." 
 $startDScluster > $NULL
}

function stopDScluster()
{
 echo "Issuing DS cluster stop on Node01 and Node02 ..."
 echo "may take awhile for all servers/applications to complete stopping after cmd is issued."  
 $stopDScluster > $NULL
}

function startDCcluster()
{
 echo "Issuing DC cluster start on Node01 and Node02 ..."
 echo "may take awhile for all servers/applications to complete startup after cmd is issued."  
 $startDCcluster > $NULL
}

function stopDCcluster()
{
 echo "Issuing DC cluster stop on Node01 and Node02 ..."
 echo "may take awhile for all servers/applications to complete stopping after cmd is issued."  
 $stopDCcluster > $NULL
}

#--------- main --------------
#
# arg2 (optional) specifies server / node scoped control
if [[ $2 ]] ; then
 case $2 in
   dmgr)  server=$dmgr ;;
   node1) server=$node1 ;;
   node2) server=$node2 ;;
   dc1)   server=$dc1 ;;
   dc2)   server=$dc2 ;;
   ds1)   server=$ds1 ;;
   ds2)   server=$ds2 ;;
   res)   server=$res ;;
  force)  force=true ;;
   *)
      echo "$2 server not found in cluster"
      echo "choose from: res, dc1,dc2,ds1,ds2, dmgr,node1,node2"
      echo "or leave blank for all servers in cluster"
      exit ;;
  esac
fi

# force executes action overriding status
if [[ $3 == "force" ]]; then force=true ; fi

# arg1 specifies cluster-scoped control
# usually sufficient for most purposes 

case $1 in
    startDS) startDScluster ;;
    stopDS)  stopDScluster ;;
    startDC) startDCcluster ;;
    stopDC)  stopDCcluster ;;
    
    start)   startCluster ;;
    stop)    stopCluster ;;
    restart) stopCluster ; startCluster ;;

    status)  clusterStatus ;;
    info)    displayInfo.sh ;;
    help)    displayInfo.sh cmd ; exit  ;;
    *)       displayInfo.sh cmd ; exit  ;;
esac
