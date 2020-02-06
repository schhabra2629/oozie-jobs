#!/usr/bin/env bash

helpFunction()
{
   echo ""
   echo "Usage: $0 -c <clustername> -u <ambari-url/CM> -w <workflow type> -o <otherComponent> -k <y|n> -f <frenquency> -s <startdate> -e <enddate>"
   echo -e "\t-c Cluster name"
   echo -e "\t-a ambari-url"
   echo -e "\t-w workflow type"
   echo -e "\t-o other component involved"
   echo -e "\t-k is cluster secure?"
   echo -e "\t-f frequency for coordinator"
   echo -e "\t-s start date for coordinator"
   echo -e "\t-e end date for coordinator"
   exit 1 # Exit script after printing help
}

while getopts "u:w:o:s:k:c:" opt
do
   case "$opt" in
      u ) AMBARI_URL="$OPTARG" ;;
      w ) WF_TYPE="$OPTARG" ;;
      o ) OTHER_COMP="$OPTARG" ;;
      k ) IS_CLUSTER_SECURE="$OPTARG" ;;
      f ) FREQ="$OPTARG" ;;
      s ) START_DATE="$OPTARG" ;;
      e ) END_DATE="$OPTARG" ;;
      c ) CLUSTER_NAME="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$AMBARI_URL" ] || [ -z "$WF_TYPE" ]  || [ -z "$IS_CLUSTER_SECURE" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

# Begin script in case all parameters are correct
echo "$AMBARI_URL"

# GET NAMENODE and RESOURCE MANAGER VALUES


NAMENODE_HOST=$(curl -u admin:shubham -s ${AMBARI_URL}/api/v1/clusters/${CLUSTER_NAME}/services/HDFS/components/NAMENODE/ |grep host_name |awk -F ' : ' '{print $2}' |sed 's/"//g')
NAMENODE_URL="hdfs://${NAMENODE_HOST}:8020"

RESOURCEMANAGER_HOST=$(curl -u admin:shubham -s ${AMBARI_URL}/api/v1/clusters/${CLUSTER_NAME}/services/YARN/components/RESOURCEMANAGER/ |grep host_name |awk -F ' : ' '{print $2}' |sed 's/"//g')
RESOURCEMANAGER_URL="${RESOURCEMANAGER_HOST}:8050"


mkdir $WF_TYPE
wget https://raw.githubusercontent.com/schhabra2629/oozie-jobs/master/oozie-samples/src/main/workflows/$WF_TYPE-wf.xml -P $WF_TYPE
hadoop fs -mkdir /tmp/$WF_TYPE
hadoop fs -put $WF_TYPE/$WF_TYPE-wf.xml  /tmp/$WF_TYPE

  case $WF_TYPE in
	shell)
	    wget https://raw.githubusercontent.com/schhabra2629/oozie-jobs/master/oozie-samples/src/main/resources/scripts/sample-script.sh -P $WF_TYPE
	    hadoop fs -put $WF_TYPE/sample-script.sh /tmp/$WF_TYPE

	    echo "jobTracker=${RESOURCEMANAGER_URL}\
nameNode=${NAMENODE_URL}
shellScript=sample-script.sh
shellScriptLoc=\${nameNode}/tmp/$WF_TYPE/sample-script.sh
oozie.wf.application.path=\${nameNode}/tmp/$WF_TYPE/shell-wf.xml" > shell-job.properties

		echo "Hello yourself!"
		;;
	hive)

	 wget https://raw.githubusercontent.com/schhabra2629/oozie-jobs/master/oozie-samples/src/main/resources/scripts/hive-script.q -P $WF_TYPE
	 hadoop fs -put $WF_TYPE/hive-script.q /tmp/$WF_TYPE

	   echo "jobTracker=${RESOURCEMANAGER_URL}\
nameNode=${NAMENODE_URL}
script=hive-script.q
scriptLoc=\${nameNode}/tmp/$WF_TYPE/hive-script.q
oozie.wf.application.path=\${nameNode}/tmp/$WF_TYPE/hive-wf.xml" > hive-job.properties

		echo "See you again!"
		break
		;;
	*)
		echo "Sorry, I don't understand"
		;;
  esac

