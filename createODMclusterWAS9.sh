#!/bin/bash
#
# createODMclusterWAS.sh <version> <remoteHostname> 
#
# version = {8110, 81051}
# remoteHostname = hostname (or IP) of remote Node02
# --------------------------------

export localOnly

if [ -z "$1" ] ; then
 echo "usage: createODMclusterWAS.sh <version> <remoteHostname>"
 echo " version={8110, 81051} "
 exit 
elif [ -z "$2" ] ; then
 echo "only local cluster member specified " 
 localOnly=true
else
  remoteHostName=$2
  remoteHost=$(ssh $remoteHostName hostname)
  remoteHostIP=$(ssh $remoteHostName hostname -i)
  if [ "$remoteHost" = "$remoteHostName" ] ||  [ "$remoteHostIP" = "$remoteHostName" ]  ; then
   echo "remote cluster member will also be created on hostname $remoteHostName"
   localOnly=false
 else
  echo "cannot connect to $remoteHostName "
  localOnly=true
  exit
 fi
fi
 
export ver=$1

# if   [ $HOSTNAME == "odm1" ] ;  then   ver="8110"
# elif [ $HOSTNAME == "odm"  ] ;  then   ver="81051" ; fi

# paths 
export WAS_HOME=/opt/IBM/WAS9/AppServer
export ODM_HOME=/opt/IBM/ODM$ver
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

function parseDSpropertiesFile()
{
 resClusterName=$(grep cluster.name $DSClusterPropfile | gawk -F= '{ print $2 }')
 resdbType=$(grep database.type $DSClusterPropfile | gawk -F= '{ print $2 }')
 resdbUser=$(grep database.user $DSClusterPropfile | gawk -F= '{ print $2 }')
 resdbPassword=$(grep database.password $DSClusterPropfile | gawk -F= '{ print $2 }')
 resdbName=$(grep database.name $DSClusterPropfile | gawk -F= '{ print $2 }')
 resdbHost=$(grep database.hostname $DSClusterPropfile | gawk -F= '{ print $2 }')
 resNode1=$(grep cluster.member.nodes  $DSClusterPropfile | gawk -F= '{ print $2 }' | gawk -F, '{ print $1 }' )
 resNode2=$(grep cluster.member.nodes  $DSClusterPropfile | gawk -F= '{ print $2 }' | gawk -F, '{ print $2 }' )
}

function parseDCpropertiesFile()
{
 dcClusterName=$(grep cluster.name $DCClusterPropfile | gawk -F= '{ print $2 }')  
 dcdbType=$(grep database.type $DCClusterPropfile | gawk -F= '{ print $2 }')
 dcdbUser=$(grep database.user $DCClusterPropfile | gawk -F= '{ print $2 }')
 dcdbPassword=$(grep database.password $DCClusterPropfile | gawk -F= '{ print $2 }')
 dcdbName=$(grep database.name $DCClusterPropfile | gawk -F= '{ print $2 }')
 dcdbHost=$(grep database.hostname $DCClusterPropfile | gawk -F= '{ print $2 }')
 dcNode1=$(grep cluster.member.nodes  $DCClusterPropfile | gawk -F= '{ print $2 }' | gawk -F, '{ print $1 }' )
 dcNode2=$(grep cluster.member.nodes  $DCClusterPropfile | gawk -F= '{ print $2 }' | gawk -F, '{ print $2 }' )
}

function validateDB()
{
 if [ -f $DSClusterPropfile ] ; then parseDSpropertiesFile ; else echo "$DSClusterPropfile not found, aborting" ; exit  ; fi
 if [ -f $DCClusterPropfile ] ; then parseDCpropertiesFile ; else echo "$DCClusterPropfile not found, aborting" ; exit  ; fi
 
 if [ $dcdbName ] ; then
  source ~db2inst1/.bashrc
  db2start
  if [ $dcdbType = "DB2" ] ; then
    dcdb=$(db2 connect to $dcdbName user $dcdbUser using $dcdbPassword  | grep -w DCDB)
    db2 disconnect all
  else
   echo "only DB2 is currently supported" 
  fi 
 fi
 if [ $resdbName ] ; then
   resdb=$(db2 connect to $resdbName user $resdbUser using $resdbPassword  | grep -w RESDB)
   db2 disconnect all;
 fi
 
 if [[ ! $dcdb ]] ; then
  echo "cannot connect to $dcdbName, aborting."
  exit 
 fi
 if [[ ! $resdb ]] ; then
  echo "cannot connect to $resdbName, aborting." 
  exit
 fi

}

function deleteLocalProfiles()
{
 manageODMclusterWAS9.sh  stop
 $WAS_HOME/bin/manageprofiles.sh -validateAndUpdateRegistry
 echo "Deleting profiles and clusters ... "
 $WAS_HOME/bin/manageprofiles.sh -delete -profileName $node01ProfileName
 $WAS_HOME/bin/manageprofiles.sh -delete -profileName $dmgrProfileName
 $WAS_HOME/bin/manageprofiles.sh -validateAndUpdateRegistry
 rm -rf $WAS_NODE01 
 rm -rf $WAS_DMGR01
}

function deleteRemoteProfiles()
{
 # manageODMclusterWAS9.sh  stop
 # $WAS_HOME/bin/manageprofiles.sh -validateAndUpdateRegistry
  echo "Deleting remote profiles ... need to implement "
 # $WAS_HOME/bin/manageprofiles.sh -delete -profileName $node02ProfileName
 # $WAS_HOME/bin/manageprofiles.sh -validateAndUpdateRegistry
 # rm -rf $WAS_NODE02
}

function deleteExistingProfiles()
{
 deleteLocalProfiles
 deleteRemoteProfiles
}

#----- main ----------
#
 validateDB
 deleteExistingProfiles
 
# uncomment next 2 lines for WAS 855
# $WAS_HOME/bin/managesdk.sh    -setCommandDefault    -sdkname 1.8_64_bundled
# $WAS_HOME/bin/managesdk.sh    -setNewProfileDefault -sdkname 1.8_64_bundled

# increase JVM Max heap for WAS cli scripts or augment will cause OutOfMemory exception
sed -i "s/-Xms256m -Xmx256m -Xquickstart/-Xms245m -Xmx4096m -Xquickstart/g" $WAS_HOME/bin/wsadmin.sh
sed -i "s/-Xms256m -Xmx256m -Xj9/-Xms256m -Xmx4096m -Xj9/g" $WAS_HOME/bin/launchWsadminListener.sh

echo "Creating $dmgrProfileName, log: $WAS_HOME/logs/manageprofiles/Dmgr01_create.log"
$WAS_HOME/bin/manageprofiles.sh -create -profileName $dmgrProfileName -profilePath $WAS_DMGR01  -templatePath $WAS_HOME/profileTemplates/management -enableAdminSecurity true $creds2

echo "Augmenting $dmgrProfileName  for decisionserver, log: $WAS_HOME/logs/manageprofiles/Dmgr01_augment.log"
$WAS_HOME/bin/manageprofiles.sh -augment -profileName $dmgrProfileName -templatePath $WAS_HOME/profileTemplates/odm/decisionserver/management -odmHome $ODM_HOME

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
 
echo "Creating $resClusterName  logs: $WAS_DMGR01/logs/odm"
$WAS_DMGR01/bin/createODMDecisionServerCluster.sh -clusterPropertiesFile $DSClusterPropfile $creds1

echo "Creating $dcClusterName, logs: $WAS_DMGR01/logs/odm"
$WAS_DMGR01/bin/createODMDecisionCenterCluster.sh -clusterPropertiesFile $DCClusterPropfile $creds1 

manageODMclusterWAS9.sh start 
