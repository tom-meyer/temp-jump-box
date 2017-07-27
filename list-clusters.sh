#!/bin/bash

function list_running_terraform_instances() {
    aws ec2 describe-instances --filter "Name=tag:Terraform,Values=true" "Name=instance-state-name,Values=running"
}

function extract_name_and_ip_and_launch_time() {
    jq -r '[.Reservations[] | .Instances[] | {Time: .LaunchTime, NodeIp: .PrivateIpAddress, NodeName: .Tags[] | select(.Key=="Name") | .Value}] | sort_by(.NodeName) | .[] | "\(.NodeIp) \(.NodeName) \(.Time)"'
}

function print_table_with_pacific_launch_time() {
    while read -r node_ip node_name time ; do
        echo "$node_ip" "$node_name" "$(TZ='America/Los_Angeles' date --date="$time" +'%Y-%m-%d %H:%M:%S %Z')"
    done | column -t
}

list_running_terraform_instances | extract_name_and_ip_and_launch_time | print_table_with_pacific_launch_time
