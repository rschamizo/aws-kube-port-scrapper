#!/bin/bash
set -e

# # # Vars set in Docker
# # AWS_REGION="eu-west-3"
# # CLUSTER_NAME="vmware-cluster"
# # S3_EXPORT_ENABLED="false"
# # S3_BUCKET_NAME="vmware-project"
# # WHITE_LIST_PORT_STRING="10250"
# # DYNAMODB_ENABLED="true"
# # DYNAMODB_TABLE="vmwareUsers"
# # DYNAMODB_INDEX="Username"
# # JOB_CREATED_IMAGE="rschamizo/node-port-scrapper"

dynamoFolder="dynamodb"
nodesFile="nodes.txt"

mkdir -p $dynamoFolder

aws eks update-kubeconfig \
  --region $AWS_REGION \
  --name $CLUSTER_NAME

kubectl get nodes -o jsonpath='{range.items[*]}{.metadata.name}{"\t"}{"\n"}{end}' > $nodesFile
sed -i "s/<white_list_port_token>/$WHITE_LIST_PORT_STRING/" job.yaml
sed -i "s/<node_port_image>/$(echo $JOB_CREATED_IMAGE | sed 's/\//\\\//')/" job.yaml

cat $nodesFile | while read line || [[ -n $line ]];
do
  nodeName=$(echo $line | awk '{ print $1}')
  yq e ".metadata.name = \"scrapper-node-$nodeName\"" -i job.yaml
  kubectl delete job scrapper-node-$nodeName --ignore-not-found
  kubectl create -f job.yaml
  kubectl wait --for=condition=complete job/scrapper-node-$nodeName
  kubectl logs job/scrapper-node-$nodeName > $nodeName
  if [ $DYNAMODB_ENABLED == "true" ]; then
    jq -e 'map(.number = {"S": .number}) | map(.protocols = {"SS": .protocols}) | map(.pids = {"SS": .pids}) | map(.program_names = {"SS": .program_names} ) | map(. = {"M": .})' $nodeName > $dynamoFolder/$nodeName
  fi
done

currentDate=$(date +'%Y-%m-%d--%H-%M')

if [ $S3_EXPORT_ENABLED == "true" ]; then
  jq -n 'reduce inputs as $s (.; .[input_filename] += {"ports": $s})' $(cat $nodesFile) > port-report-$currentDate.json
  aws s3 cp port-report-$currentDate.json s3://$S3_BUCKET_NAME
fi

cd $dynamoFolder
if [ $DYNAMODB_ENABLED == "true" ]; then
  numNodes=$(cat ../$nodesFile| wc -l)
  if [ "$numNodes" -eq "1" ]; then
    nodeName=$(cat ../$nodesFile | tr -d '\t')
    jq -e "{\"$nodeName\": {\"M\":{\"ports\":{\"L\": . }}}}" $(cat ../$nodesFile) > dynamodb-report-staging.json
  else
    jq -n 'reduce inputs as $s (.; .[input_filename] += {"M":{"ports":{"L": $s }}})' $(cat ../$nodesFile) > dynamodb-report-staging.json
  fi
  
  jq -e "{\"$DYNAMODB_TABLE\":[{\"PutRequest\":{\"Item\": {\"$DYNAMODB_INDEX\": {\"S\":\"$currentDate\"}, \"Nodes\": {\"M\": . } } }}]}" dynamodb-report-staging.json > dynamodb-port-report-$currentDate.json
  aws dynamodb batch-write-item --request-items file://dynamodb-port-report-$currentDate.json > batch.json
fi
