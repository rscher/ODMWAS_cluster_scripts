#!/bin/bash
# deleteODM892clusterWAS855.sh
#
# --------------------------------

export WAS_HOME=/opt/IBM/WBM/v8.5.7
export ODM_HOME=/opt/IBM/ODM892
export JAVA_HOME=$ODM_HOME/jdk
export WAS_PROFILE=$WAS_HOME/profiles
export WAS_DMGR01=$WAS_PROFILE/Dmgr01
export WAS_NODE01=$WAS_PROFILE/ODMMachine01

# source ~db2inst1/.bashrc
# db2start

echo "Stopping clusters and servers... "
./stopODM892clusterWAS855.sh
echo "Deleting profiles and clusters ... "

$WAS_HOME/bin/manageprofiles.sh -delete -profileName ODMMachine01
$WAS_HOME/bin/manageprofiles.sh -delete -profileName Dmgr01
$WAS_HOME/bin/manageprofiles.sh -validateAndUpdateRegistry

rm -rf $WAS_NODE01 
rm -rf $WAS_DMGR01

echo " Existing profiles on this host ... "
$WAS_HOME/bin/manageprofiles.sh -listProfiles
