#!/bin/bash

function list_running_terraform_instances() {
    aws ec2 describe-instances --filter "Name=tag:Terraform,Values=true" "Name=instance-state-name,Values=running"
}

function extract_name_and_ip_and_launch_time() {
    jq -r '[.Reservations[] | .Instances[] | {Time: .LaunchTime, NodeIp: .PrivateIpAddress, NodeName: .Tags[] | select(.Key=="Name") | .Value, URL: .Tags[] | select(.Key=="PipelineUrl") | .Value}] | sort_by(.URL) | .[] | "\(.NodeIp) \(.NodeName) \(.Time) \(.URL)"'
}

function print_table_with_pacific_launch_time() {
    while read -r node_ip node_name time url ; do
        cali_date="$(TZ='America/Los_Angeles' date --date="$time" +'%Y-%m-%d %H:%M:%S %Z')"
        echo -e "$node_name \t $node_ip \t $cali_date \t $url"
    done | column -t -s $'\t'
}

list_running_terraform_instances | extract_name_and_ip_and_launch_time | print_table_with_pacific_launch_time
