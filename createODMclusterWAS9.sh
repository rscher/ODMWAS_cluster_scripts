#!/bin/bash
#
# createODMclusterWAS.sh <remoteHostname> 
#
# remoteHostname = hostname (or IP) of remote Node02
# --------------------------------

export localOnly

if [ -z "$1" ] ; then
 localOnly=true
 echo "only local cluster cluster member will created" 
else
  remoteHostName=$1
  remoteHost=$(ssh $remoteHostName hostname)
  remoteHostIP=$(ssh $remoteHostName hostname -i)
  if [ "$remoteHost" = "$remoteHostName" ] ||  [ "$remoteHostIP" = "$remoteHostName" ]  ; then
   echo "remote cluster member will also be created on hostname $remoteHostName"
   localOnly=false
  else
   echo "cannot connect to $remoteHostName "
   exit
  fi
fi
 
# paths/vars 
export WAS_HOME=/opt/IBM/WAS9/AppServer
export ODM_HOME=/opt/IBM/ODM8111
export WAS_PROFILE=$WAS_HOME/profiles
export dmgrProfileName=Dmgr01
export node01ProfileName=ODMMachine01
export node02ProfileName=ODMMachine02
export WAS_DMGR01=$WAS_PROFILE/$dmgrProfileName
export WAS_NODE01=$WAS_PROFILE/$node01ProfileName
export WAS_NODE02=$WAS_PROFILE/$node02ProfileName

SOAPport=8879 
creds="-username admin -password admin"
creds1="-adminUsername admin -adminPassword admin"
creds2="-adminUserName admin -adminPassword admin"

# Variables used must match cluster properties files and topology
DSClusterPropfile=./ODMDecisionServerCluster.properties
DCClusterPropfile=./ODMDecisionCenterCluster.properties

#----- main ----------
 
# increase JVM Max heap for WAS cli scripts or augment will cause OutOfMemory exception
sed -i "s/-Xms256m -Xmx256m -Xquickstart/-Xms245m -Xmx4096m -Xquickstart/g" $WAS_HOME/bin/wsadmin.sh
sed -i "s/-Xms256m -Xmx256m -Xj9/-Xms256m -Xmx4096m -Xj9/g" $WAS_HOME/bin/launchWsadminListener.sh

# ----- Create WAS Dmgr Profile ----------
echo "Creating $dmgrProfileName, log: $WAS_HOME/logs/manageprofiles/Dmgr01_create.log"
$WAS_HOME/bin/manageprofiles.sh -create -profileName $dmgrProfileName -profilePath $WAS_DMGR01  -templatePath $WAS_HOME/profileTemplates/management -enableAdminSecurity true $creds2

# ----- Augment Decision Server  ----------
echo "Augmenting $dmgrProfileName  for decisionserver, log: $WAS_HOME/logs/manageprofiles/Dmgr01_augment.log"
$WAS_HOME/bin/manageprofiles.sh -augment -profileName $dmgrProfileName -templatePath $WAS_HOME/profileTemplates/odm/decisionserver/management -odmHome $ODM_HOME

# ----- Augment Decision Center  ----------
echo "Augmenting $dmgrProfileName for decisioncenter, log: $WAS_HOME/logs/manageprofiles/Dmgr01_augment.log"
$WAS_HOME/bin/manageprofiles.sh -augment -profileName $dmgrProfileName -templatePath $WAS_HOME/profileTemplates/odm/decisioncenter/management -odmHome $ODM_HOME

echo "Starting $dmgrProfileName"
$WAS_DMGR01/bin/startManager.sh

# create local node
echo "Creating Cluster Member: $node01ProfileName log: $WAS_HOME/logs/manageprofiles/"$node01ProfileName"_create.log"
$WAS_HOME/bin/manageprofiles.sh -create -templatePath $WAS_HOME/profileTemplates/managed  -profileName $node01ProfileName -profilePath $WAS_NODE01  -nodeName $resNode1 

# federate local node to cluster
echo "Federating Cluster Member: $node01ProfileName to $dmgrProfileName on $HOSTNAME"
$WAS_NODE01/bin/addNode.sh  $HOSTNAME $SOAPport $creds 

# create remote node and federate to dmgr
if [ $localOnly == "false" ] ; then
 echo "Creating remote Cluster Member: $node02ProfileName on host: $remoteHostName   log: $remoteHostName: $WAS_HOME/logs/manageprofiles/"$node02ProfileName"_create.log"
 cmd=$(echo "$WAS_HOME/bin/manageprofiles.sh -create -templatePath $WAS_HOME/profileTemplates/managed  -profileName $node02ProfileName -profilePath $WAS_NODE02  -nodeName $resNode2")
 ssh $remoteHostName $cmd

 echo "Federating remote Cluster Member: $node02ProfileName on host: $remoteHostName to $dmgrProfileName on $HOSTNAME"
 cmd=$(echo "$WAS_NODE02/bin/addNode.sh  $HOSTNAME $SOAPport $creds")
 ssh $remoteHostName $cmd
fi
 
# ----- Create Decision Server Cluster ---------- 
echo "Creating $resClusterName  logs: $WAS_DMGR01/logs/odm"
$WAS_DMGR01/bin/createODMDecisionServerCluster.sh -clusterPropertiesFile $DSClusterPropfile $creds1

# ----- Create Decision Center Cluster ----------
echo "Creating $dcClusterName, logs: $WAS_DMGR01/logs/odm"
$WAS_DMGR01/bin/createODMDecisionCenterCluster.sh -clusterPropertiesFile $DCClusterPropfile $creds1 
