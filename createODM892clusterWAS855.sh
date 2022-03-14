#!/bin/bash
#
# createODM892clusterWAS855.sh - 
# 
# pre-reqs: WAS855 and ODM packages installed
# --------------------------------
#
#  2 Node Production Cluster Topology 
# -----------------------------------
# hostnames odm, odm1 shown for example purposes only
#
# Dmgr01 8.5.5.18  (Cell) (Local, hostname=odm)
# --> DecisionCenterCluster (DC-Cluster) 
#   --> Cluster members
#    --> Node01 (ND 8.5.5.18) (Local, hostname=odm) 
#      --> Node01-DCServer  
#    --> Node02 (ND 8.5.5.18) (Remote, hostname=odm1)  
#      --> Node02-DCServer
#
# --> DecisionServerCluster (DS-Cluster) 
#   --> Cluster members
#     --> Node01 (ND 8.5.5.18) (Local, hostname=odm) 
#       --> Node01-DSServer
#     --> Node02 (ND 8.5.5.18) (Remote, hostname=odm1)
#       --> Node02-DSServer 
#
# Variables used must match cluster properties files and topology
DSClusterPropfile=./ODMDecisionServerCluster.properties
DCClusterPropfile=./ODMDecisionCenterCluster.properties

# profiles on this host (local) -Dmgr01 and Node01
WAS_HOME=/opt/IBM/WBM/v8.5.7
ODM_HOME=/opt/IBM/ODM892
WAS_PROFILES=$WAS_HOME/profiles
dmgrProfile=$WAS_PROFILES/Dmgr01
node01Profile=$WAS_PROFILES/ODMMachine01
node01Name=Node01

# profile on remote host- Node02
WAS_HOME_REMOTE=/opt/IBM/WebSphere/AppServer
WAS_PROFILES_REMOTE=$WAS_HOME_REMOTE/profiles
node02Profile=$WAS_PROFILES_REMOTE/ODMMachine02
node02profileName=ODMMachine02
node02name=Node02
node02hostname=odm1
 

# setup sdk 1.8 for WAS v8.5.5 only
$WAS_HOME/bin/managesdk.sh    -setCommandDefault    -sdkname 1.8_64_bundled
$WAS_HOME/bin/managesdk.sh    -setNewProfileDefault -sdkname 1.8_64_bundled


# modify WAS wsadmin scripts to increase JVM Heap max value to 4G, otherwise augmentation will cause OutOfMemory exception
sed -i "s/-Xms256m -Xmx256m -Xquickstart/-Xms256m -Xmx4096m -Xquickstart/g" $WAS_HOME/bin/wsadmin.sh
sed -i "s/-Xms256m -Xmx256m -Xj9/-Xms256m -Xmx4096m -Xj9/g" $WAS_HOME/bin/launchWsadminListener.sh

 echo "Creating Dmgr01, log: $WAS_HOME/logs/manageprofiles/Dmgr01_create.log"
 $WAS_HOME/bin/manageprofiles.sh -create -templatePath $WAS_HOME/profileTemplates/management -enableAdminSecurity true -adminUserName admin -adminPassword admin

 echo "Augmenting Dmgr01 for decisionserver, log: $WAS_HOME/logs/manageprofiles/Dmgr01_augment.log"
 $WAS_HOME/bin/manageprofiles.sh -augment -profileName Dmgr01 -templatePath $WAS_HOME/profileTemplates/odm/decisionserver/management -odmHome $ODM_HOME

 echo "Augmenting Dmgr01 for decisioncenter, log: $WAS_HOME/logs/manageprofiles/Dmgr01_augment.log"
 $WAS_HOME/bin/manageprofiles.sh -augment -profileName Dmgr01 -templatePath $WAS_HOME/profileTemplates/odm/decisioncenter/management -odmHome $ODM_HOME

 echo "Starting Dmgr01"
 $WAS_DMGR01/bin/startManager.sh

 echo "Creating Cluster Member: log: $WAS_HOME/logs/manageprofiles/ODMMachine01_create.log"
 $WAS_HOME/bin/manageprofiles.sh -create -templatePath $WAS_HOME/profileTemplates/managed  -profileName ODMMachine01 -nodeName Node01

 echo "Federating Cluster Member: ODMMachine01 to Dmgr01 on $HOSTNAME"
 $WAS_NODE01/bin/addNode.sh  $HOSTNAME 8879 -username admin -password admin
 
 echo "Creating createODMDecisionServerCluster, logs: $WAS_DMGR01/logs/odm"
 $WAS_DMGR01/bin/createODMDecisionServerCluster.sh -clusterPropertiesFile $DSClusterPropfile -adminUsername admin -adminPassword admin

 echo "Creating createODMDecisionCenterCluster, logs: $WAS_DMGR01/logs/odm"
 $WAS_DMGR01/bin/createODMDecisionCenterCluster.sh -clusterPropertiesFile $DCClusterPropfile  -adminUsername $adminUsername -adminPassword $adminPassword
