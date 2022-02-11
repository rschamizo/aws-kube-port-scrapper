#!/bin/bash

set -e

# # # Vars set in Docker
# # WHITE_LIST_PORT_STRING="29754 5353 17500"

netstat -tulpnl | grep LISTEN | tail -n +3 > ports.txt
echo "[]" > ports_report.json

whitelistPortsArray=()
for port in $WHITE_LIST_PORT_STRING
do
   whitelistPortsArray+=($port)
done

cat ports.txt | while read line || [[ -n $line ]];
do
  port=$(echo $line | awk '{ print $4 }' | sed "s/.*:\(.*\)/\\1/")
  if ! [[ ${whitelistPortsArray[*]} =~ $(echo "\<$port\>") ]]; then
    protocol=$(echo $line | awk '{ print $1}')
    pid="$(echo $line | awk '{ print $7}' | sed "s/\(\\w*\)\/.*/\\1/")"
    program_name="$(echo $line | awk '{ print $7}'| sed "s/\(.*\)\/\(.*\)/\\2/")"

    cat <<< $(jq --arg port "$port" --arg program_name "$program_name" --arg pid "$pid" --arg protocol "$protocol" \
      -e '. |= (.+ [{"number": $port, "protocols": [$protocol], "program_names": [$program_name], "pids": [$pid]}] )' \
      ports_report.json) > ports_report.json
  fi
done

cat <<< $(jq -e ". | group_by(.number) | .[] | {\"number\": .[0].number, \"protocols\": [.[].protocols] | unique | add, \
  \"program_names\": [.[].program_names] | unique | add, \"pids\": [.[].pids] | unique | add}" ports_report.json | jq -s '.')
