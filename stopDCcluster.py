import sys

AdminControl.invoke('WebSphere:name=DecisionCenterCluster,process=dmgr,platform=common,node=odm1CellManager01,version=9.0.5.10,type=Cluster,mbeanIdentifier=DecisionCenterCluster,cell=odm1Cell01,spec=1.0', 'stop')
