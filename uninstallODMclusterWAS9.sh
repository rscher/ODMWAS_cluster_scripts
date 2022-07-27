#!/bin/bash
#
# updateODMclusterWAS.sh <version> 
#
# version = {8110, 81051}
# --------------------------------

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


#----- main ----------
#

echo "Uninstalling $resClusterName  logs: $WAS_DMGR01/logs/odm"
echo "$WAS_DMGR01/bin/createODMDecisionServerCluster.sh $creds1 -clusterPropertiesFile $DSClusterPropfile   -uninstall -dmgrHostName $HOSTNAME -dmgrPort $SOAPport"
$WAS_DMGR01/bin/createODMDecisionServerCluster.sh $creds1 -clusterPropertiesFile $DSClusterPropfile   -uninstall -dmgrHostName $HOSTNAME -dmgrPort $SOAPport  

echo "Uninstalling $dcClusterName, logs: $WAS_DMGR01/logs/odm"
echo "$WAS_DMGR01/bin/createODMDecisionCenterCluster.sh $creds1  -clusterPropertiesFile $DCClusterPropfile   -uninstall -dmgrHostName $HOSTNAME -dmgrPort $SOAPport"

$WAS_DMGR01/bin/createODMDecisionCenterCluster.sh $creds1  -clusterPropertiesFile $DCClusterPropfile   -uninstall -dmgrHostName $HOSTNAME -dmgrPort $SOAPport  

# manageODMclusterWAS9.sh start 
