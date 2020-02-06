# oozie-jobs

# Oozie Sample Job generator has two phases:

1. Generation of Job Configs ( Property File, Workflow, Coordinnator and Other resources needed)

2. Deploy app on Oozie

#How to Run: ( With Commands) 

Step 1:

Usage: ./generateOozieJobConfigs.sh -c <clustername> -u <ambari-url/CM> -w <workflow type> -m <otherComponent> -k <y|n> -f <frenquency> -s <startdate> -e <enddate> -o <oozie-url>
	-c Cluster name
	-a ambari-url (Optional)
	-w workflow type
	-m other component involved (Optional)
	-k is cluster secure? (Optional)
	-f frequency for coordinator (Optional)
	-s start date for coordinator (Optional)
	-e end date for coordinator (Optional)
    
Some of parameters are optional. Step1 will generate script "deploy.sh"
  
Step 2:

./deploy.sh 

Note : Please run these scripts on node where oozie-client and ambari-agent is installed.


