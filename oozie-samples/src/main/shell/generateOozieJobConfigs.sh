#!/usr/bin/env bash

#!/bin/bash

helpFunction()
{
   echo ""
   echo "Usage: $0 -c <clustername> -u <ambari-url/CM> -w <workflow type> -m <otherComponent> -k <y|n> -f <frenquency> -s <startdate> -e <enddate> -o <oozie-url>"
   echo -e "\t-c Cluster name"
   echo -e "\t-a ambari-url"
   echo -e "\t-w workflow type"
   echo -e "\t-m other component involved"
   echo -e "\t-k is cluster secure?"
   echo -e "\t-f frequency for coordinator"
   echo -e "\t-s start date for coordinator"
   echo -e "\t-e end date for coordinator"
   exit 1 # Exit script after printing help
}

########################################## Parsing Opts OPTS ##########################################
while getopts "u:w:m:s:k:c:o:" opt
do
   case "$opt" in
      u ) AMBARI_URL="$OPTARG" ;;
      w ) WF_TYPE="$OPTARG" ;;
      m ) OTHER_COMP="$OPTARG" ;;
      k ) IS_CLUSTER_SECURE="$OPTARG" ;;
      f ) FREQ="$OPTARG" ;;
      s ) START_DATE="$OPTARG" ;;
      e ) END_DATE="$OPTARG" ;;
      c ) CLUSTER_NAME="$OPTARG" ;;
      o ) OOZIE_URL="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

if [ -z "$AMBARI_URL" ]
then
AMBARI_HOST=$(cat /etc/ambari-agent/conf/ambari-agent.ini |grep hostname|awk -F'=' '{print $2}')
AMBARI_URL="http://${AMBARI_HOST}:8080"
fi

if [ -z "$OOZIE_URL" ]
then
OOZIE_URL=$(grep -A1 oozie.base.url /etc/oozie/conf/oozie-site.xml |tail -1 |sed 's/<\/value>//g' |sed 's/<value>//g' |sed 's/ //g')
fi

KERBEROS_STATUS=$(grep -A1 hadoop.security.authentication /etc/hadoop/conf/core-site.xml |grep kerberos)

if [ ! -z "$KERBEROS_STATUS" ]
then
IS_CLUSTER_SECURE=y
fi


########################################## Print helpFunction in case parameters are empty ##########################################
if  [ -z "${WF_TYPE}" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

##########################################  Begin script in case all parameters are correct ##########################################
echo "$AMBARI_URL"


CLUSTER_NAME=$(curl -u admin:shubham -s ${AMBARI_URL}/api/v1/clusters|grep cluster_name |awk -F ' : ' '{print $2}' |sed 's/"//g' |sed 's/,//g')

##########################################  NameNode and Resource Manager Values  ##########################################



NAMENODE_HOST=$(curl -u admin:shubham -s ${AMBARI_URL}/api/v1/clusters/${CLUSTER_NAME}/services/HDFS/components/NAMENODE/ |grep host_name |awk -F ' : ' '{print $2}' |sed 's/"//g')
NAMENODE_URL="hdfs://${NAMENODE_HOST}:8020"

RESOURCEMANAGER_HOST=$(curl -u admin:shubham -s ${AMBARI_URL}/api/v1/clusters/${CLUSTER_NAME}/services/YARN/components/RESOURCEMANAGER/ |grep host_name |awk -F ' : ' '{print $2}' |sed 's/"//g')
RESOURCEMANAGER_URL="${RESOURCEMANAGER_HOST}:8050"


##########################################  Generating property file and deployment script  ##########################################

rm -f deploy.sh
echo "Creating Local directory for action"
mkdir ${WF_TYPE}

wget -nv https://raw.githubusercontent.com/schhabra2629/oozie-jobs/master/oozie-samples/src/main/workflows/${WF_TYPE}-wf.xml -P ${WF_TYPE}
echo "hadoop fs -mkdir /tmp/${WF_TYPE}" >> deploy.sh
echo "hadoop fs -put ${WF_TYPE}/${WF_TYPE}-wf.xml  /tmp/${WF_TYPE}" >> deploy.sh

  case ${WF_TYPE} in
	shell)
	PROP_FILE_NAME="shell-job.properties"
	echo "We are in Shell Action!"
	    wget -nv https://raw.githubusercontent.com/schhabra2629/oozie-jobs/master/oozie-samples/src/main/resources/scripts/sample-script.sh -P $WF_TYPE
	    echo "hadoop fs -put $WF_TYPE/sample-script.sh /tmp/$WF_TYPE" >> deploy.sh
	    echo "jobTracker=${RESOURCEMANAGER_URL}
        nameNode=${NAMENODE_URL}
        shellScript=sample-script.sh
        shellScriptLoc=\${nameNode}/tmp/$WF_TYPE/sample-script.sh
        oozie.wf.application.path=\${nameNode}/tmp/$WF_TYPE/shell-wf.xml
        oozie.use.system.libpath=true" > $PROP_FILE_NAME

		;;

	hive)
     PROP_FILE_NAME=hive-job.properties
     echo "We are in Hive Action!"
	 wget -nv https://raw.githubusercontent.com/schhabra2629/oozie-jobs/master/oozie-samples/src/main/resources/scripts/hive-script.q -P ${WF_TYPE}
	 echo "hadoop fs -put $WF_TYPE/hive-script.q /tmp/$WF_TYPE"  >> deploy.sh
     echo "jobTracker=${RESOURCEMANAGER_URL}
        nameNode=${NAMENODE_URL}
        script=hive-script.q
        scriptLoc=\${nameNode}/tmp/${WF_TYPE}/hive-script.q
        oozie.wf.application.path=\${nameNode}/tmp/${WF_TYPE}/hive-wf.xml
        oozie.use.system.libpath=true" > ${PROP_FILE_NAME}
		;;

    spark)
     PROP_FILE_NAME=hive-job.properties
     echo "We are in spark Action!"
	 wget -nv https://raw.githubusercontent.com/schhabra2629/oozie-jobs/master/oozie-samples/src/main/resources/scripts/hive-script.q -P ${WF_TYPE}
	 echo "hadoop fs -put $WF_TYPE/hive-script.q /tmp/$WF_TYPE"  >> deploy.sh
     echo "jobTracker=${RESOURCEMANAGER_URL}
        nameNode=${NAMENODE_URL}
        script=hive-script.q
        scriptLoc=\${nameNode}/tmp/$WF_TYPE/hive-script.q
        oozie.wf.application.path=\${nameNode}/tmp/$WF_TYPE/hive-wf.xml
        oozie.use.system.libpath=true" > ${PROP_FILE_NAME}
		;;

	*)
		echo "Sorry, I don't understand"
		;;
  esac

##########################################  Check Workflow status  ##########################################
echo "WF_ID=\`oozie job --oozie ${OOZIE_URL} -config ${PROP_FILE_NAME} -run| awk -F': ' '{print \$2}'\`" >> deploy.sh
echo "echo \"Check Workflow Information using command : oozie job --oozie ${OOZIE_URL} -info \${WF_ID}\"" >> deploy.sh

if [ "$WF_TYPE" != "ssh" ]
then
  echo "while true
        do
            status=\`oozie job --oozie ${OOZIE_URL} -info \${WF_ID} |grep job_\`
            if [ ! -z \"\${status}\" ]
            then
                break
            fi
        echo \"Job is not submitted to Yarn yet.... Waiting ....\"
        done

   yarn_app=\`oozie job --oozie ${OOZIE_URL} -info \${WF_ID} |grep job_ |awk '{print \$3}'|sed 's/job/application/g'\` " >> deploy.sh

echo "echo \"Command for yarn application logs : yarn logs -applicationId \$yarn_app\"" >> deploy.sh
chmod 755 deploy.sh
else
echo "Yarn job will not be launched"
fi
