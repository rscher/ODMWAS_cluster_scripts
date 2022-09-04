import sys

AdminControl.invoke('WebSphere:name=DecisionServerCluster,process=dmgr,platform=common,node=odm1CellManager01,version=9.0.5.10,type=Cluster,mbeanIdentifier=DecisionServerCluster,cell=odm1Cell01,spec=1.0', 'start')

# RippleStart option
# AdminControl.invoke('WebSphere:name=DecisionServerCluster,process=dmgr,platform=common,node=odm1CellManager01,version=9.0.5.10,type=Cluster,mbeanIdentifier=DecisionServerCluster,cell=odm1Cell01,spec=1.0', 'rippleStart')
