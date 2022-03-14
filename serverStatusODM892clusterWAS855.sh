#!/bin/bash
#
# createODM8105clusterWAS855.sh
#
# --------------------------------

export WAS_HOME=/opt/IBM/WBM/v8.5.7
export ODM_HOME=/opt/IBM/ODM892
export JAVA_HOME=$ODM_HOME/jdk
export WAS_PROFILE=$WAS_HOME/profiles
export WAS_DMGR01=$WAS_PROFILE/Dmgr01
export WAS_NODE01=$WAS_PROFILE/ODMMachine01


$WAS_HOME/bin/managesdk.sh    -setCommandDefault    -sdkname 1.8_64_bundled
$WAS_HOME/bin/managesdk.sh    -setNewProfileDefault -sdkname 1.8_64_bundled

$WAS_DMGR01/bin/serverStatus.sh -all -username admin -password admin
$WAS_NODE01/bin/serverStatus.sh -all -username admin -password admin
