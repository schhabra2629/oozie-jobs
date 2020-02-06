#!/usr/bin/env bash

helpFunction()
{
   echo ""
   echo "Usage: $0 -u <ambari-url/CM> -w <workflow type> -o <otherComponent> -k <y|n> -f <frenquency> -s <startdate> -e <enddate>"
   echo -e "\t-a ambari-url"
   echo -e "\t-w workflow type"
   echo -e "\t-o other component involved"
   echo -e "\t-k is cluster secure?"
   echo -e "\t-f frequency for coordinator"
   echo -e "\t-s start date for coordinator"
   echo -e "\t-e end date for coordinator"
   exit 1 # Exit script after printing help
}

while getopts "u:w:o:s:" opt
do
   case "$opt" in
      u ) AMBARI_URL="$OPTARG" ;;
      w ) WF_TYPE="$OPTARG" ;;
      o ) OTHER_COMP="$OPTARG" ;;
      k ) IS_CLUSTER_SECURE="$OPTARG" ;;
      f ) FREQ="$OPTARG" ;;
      s ) START_DATE="$OPTARG" ;;
      e ) END_DATE="$OPTARG" ;;
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

NAMENODE_HOST=$(curl -u admin:shubham -s http://172.25.42.144:8080/api/v1/clusters/c1293/services/HDFS/components/NAMENODE/ |grep host_name |awk -F ' : ' '{print $2}' |sed 's/"//g')
NAMENODE_URL="hdfs://${NAMENODE_HOST}:8020"

RESOURCEMANAGER_HOST=$(curl -u admin:shubham -s http://172.25.42.144:8080/api/v1/clusters/c1293/services/YARN/components/RESOURCEMANAGER/ |grep host_name |awk -F ' : ' '{print $2}' |sed 's/"//g')
RESOURCEMANAGER_URL="${RESOURCEMANAGER_HOST}:8050"


  case $WF_TYPE in
	shell)

	    mkdir $WF_TYPE
	    wget <> -P $WF_TYPE
	    wget <> -P $WF_TYPE

		echo "Hello yourself!"
		;;
	bye)
		echo "See you again!"
		break
		;;
	*)
		echo "Sorry, I don't understand"
		;;
  esac

