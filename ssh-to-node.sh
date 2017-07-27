#! /bin/bash


IFS=$'\n\t'

download_tfstate_file() {
    local env_name=$1

    mkdir -p clusters

    tfstate_path="$(aws s3 ls --recursive s3://gpdb5-pipeline-dynamic-terraform/ | grep -o "prod/.*/$env_name.tfstate")"

    if [ -z "$tfstate_path" ]; then
        tfstate_path="$(aws s3 ls --recursive s3://gpdb5-pipeline-dynamic-terraform/ | grep -o "dev/.*/$env_name.tfstate")"
    fi

    if [ -z "$tfstate_path" ]; then
        echo "Couldn't find tfstate file in s3://gpdb5-pipeline-dynamic-terraform/ for environment '$env_name'"
        exit 1
    fi

    aws s3 cp s3://gpdb5-pipeline-dynamic-terraform/"$tfstate_path" "clusters/$env_name.tfstate"

    if [ $? -ne 0 ]; then
        exit 1
    fi
}

generate_env_files() {
    cluster_name=$1
    tfstate_path=clusters/"$cluster_name".tfstate
    env_files_dir=clusters/"$cluster_name"_env_files
    abs_env_files_dir="$(pwd)"/clusters/"$cluster_name"_env_files

    if [ -d "$env_files_dir" ]; then
        rm -rf "$env_files_dir"
    fi

    mkdir -p "$env_files_dir"

    terraform output -state="$tfstate_path" --json | jq -r .cluster_private_key_pem.value > "$env_files_dir"/private_key.pem
    chmod 600 "$env_files_dir"/private_key.pem

    terraform output -state="$tfstate_path" --json | jq -r .cluster_public_key_pem.value > "$env_files_dir"/public_key.pem
    chmod 600 "$env_files_dir"/public_key.pem

    terraform output -state="$tfstate_path" --json | jq -r .cluster_public_key_openssh.value > "$env_files_dir"/public_key.openssh

    terraform output -state="$tfstate_path" --json | jq -r .etc_host.value[] > "$env_files_dir"/etc_hostfile

    terraform output -state="$tfstate_path" --json | jq -r .cluster_host_list.value[] > "$env_files_dir"/hostfile_all

    terraform output -state="$tfstate_path" --json | jq -r .cluster_host_list.value[] | grep -E -v '[s]?mdw' > "$env_files_dir"/hostfile_init

    IFS=$'\n';

    echo StrictHostKeyChecking no > "$env_files_dir"/ssh_config
    echo UserKnownHostsFile /dev/null >> "$env_files_dir"/ssh_config

    while read -r LINE; do
        IP=$(echo "$LINE" | cut -d' ' -f1)
        HOSTNAME=$(echo "$LINE" | cut -d' ' -f2)
        NODENAME=$(echo "$LINE" | cut -d' ' -f3)

cat <<EOF >> "$env_files_dir"/ssh_config

Host $HOSTNAME
  HostName $IP
  User gpadmin
  IdentityFile $abs_env_files_dir/private_key.pem

Host $NODENAME
  HostName $IP
  User centos
  IdentityFile $abs_env_files_dir/private_key.pem

EOF

    done < "$env_files_dir"/etc_hostfile
    # see https://stackoverflow.com/a/1521498 ( if the loop body may read from standard input )

    chmod 600 "$env_files_dir"/ssh_config
    chmod 600 "$env_files_dir"/private_key.pem
}

node=$1

if [ -z "$node" ] || [ "$node" == "-h" ] || [ "$node" == "--help" ] ; then
    echo "Usage: $0 CLUSTER_NAME"
    exit 1
else
    cluster_name="$(echo "$node" | sed 's/^ccp-//' | sed 's/-[0-9]$//')"
fi

if echo "$0" | grep -q '.*ssh-to-master.sh$' ; then
    node=mdw
fi

download_tfstate_file "$cluster_name"
generate_env_files "$cluster_name"
echo ssh -F clusters/"$cluster_name"_env_files/ssh_config "$node"
ssh -F clusters/"$cluster_name"_env_files/ssh_config "$node"

