Usage
-----

Invoke `list-clusters.sh` with no arguments to show a table of running cluster nodes.

Copy a node name from the list produced by `list-clusters.sh` and use it as the
first argment to either of the `ssh-to-*.sh` scripts.

The `ssh-to-node.sh` takes a node name such as ccp-orchid-grasp-1 and will ssh
directly to that box as the *gpadmin* user.

The `ssh-to-node.sh` takes a cluster name, such as orchid-grasp, or a node
name, such as ccp-orchid-grasp-1, and will ssh to the master node *mdw*, as the
*centos* user.

Jump box setup
--------------

sudo yum install wget vim unzip

curl https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py
sudo python /tmp/get-pip.py
sudo pip install awscli

wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
chmod +x jq-linux64
sudo mv jq-linux64 /usr/local/bin/jq

wget https://releases.hashicorp.com/terraform/0.9.11/terraform_0.9.11_linux_amd64.zip
unzip terraform_0.9.11_linux_amd64.zip
sudo mv terraform /usr/local/bin/

echo export AWS_ACCESS_KEY_ID=ZOMG-PUT-SOMETHING-HERE >> ~/.bash_profile
echo export AWS_SECRET_ACCESS_KEY=OMG-REPLACE-ME-LOL >> ~/.bash_profile
echo export AWS_DEFAULT_REGION=us-west-2 >> ~/.bash_profile
