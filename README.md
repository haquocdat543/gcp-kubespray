# gcp-kubespray
Setup k8s cluster using Kubespray integrated with Ansible on Google Cloud Platform

This guide is based on [kubespray-github](https://github.com/kubernetes-sigs/kubespray). Please view their guide first.
### 1. Prerequisites
* A verified GCP account
* [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
### 2. Get started
#### 1. Configure variables
Replace `$value` with your real project id
```
export TF_VAR_projectId="$value"
```
Replace `$value` with your real ssh public key
```
export TF_VAR_ssh-key="$value"
```
#### 2. Initialize infrastructure
```
terraform init
```
```
terraform plan
```
```
terraform apply --auto-approve
```
#### 3. Configure cluster on master node
##### ssh to master node
##### Create project directory
```
mkdir -p homelab/kubernetes
cd homelab/kubernetes
```
##### Create project directory

```
python3 -m venv kubespray-venv
source kubespray-venv/bin/activate
```

##### Install Ansible
```
cd kubespray
pip install -U -r requirements.txt
```

##### Create host inventory
Why `102`, `103`, `104`. It is internal ip addresses of server defined in `compute-instance.tf`
```
declare -a IPS=(10.0.0.102 10.0.0.103 10.0.0.104)
cd ../ 
mkdir -p cluster/homelab-k8s
CONFIG_FILE=cluster/homelab-k8s/hosts.yaml python3 kubespray/contrib/inventory_builder/inventory.py ${IPS[@]}
```

##### Create host inventory
```
cat << EOF | sudo tee -a ~/homelab/kubernetes/cluster/homelab-k8s/cluster-config.yaml
cluster_name: mycluster
kube_version: v1.28.1
EOF
```
##### Copy ssh key
let copy `private key` to ssh to `worker servers` and set permission
```
read -p "$(echo -e "Enter private key [PrivateKey]: ")" key
key=${key:-PrivateKey}
cat << EOF | sudo tee -a ~/.ssh/id_rsa
$key
EOF
```
Set permission
```
chmod 400 ~/.ssh/id_rsa
```

##### Edit hosts.yaml
add following line below each node's `access_ip`:
```
ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

##### Inspect hosts.yaml
```
cat cluster/homelab-k8s/hosts.yaml
```

##### Inspect cluster-config.yaml
```
cat cluster/homelab-k8s/cluster-config.yaml
```

#### 4. Deploy cluster
##### Deploy
Replace `$ssh-user` with your real user to ssh to servers
```
cd kubespray
ansible-playbook -i ../cluster/homelab-k8s/hosts.yaml -e @../cluster/homelab-k8s/cluster-config.yaml --user=$ssh-user --become --become-user=root cluster.yml
```

##### Upgrade cluster
Replace `$ssh-user` with your real user to ssh to servers
```
cd kubespray
ansible-playbook -i ../cluster/homelab-k8s/hosts.yaml -e @../cluster/homelab-k8s/cluster-config.yaml --user=$ssh-user --become --become-user=root upgrade-cluster.yml
```
##### Scale down cluster
Replace `$ssh-user` with your real user to ssh to servers
```
cd kubespray
ansible-playbook -i ../cluster/homelab-k8s/hosts.yaml -e @../cluster/homelab-k8s/cluster-config.yaml --user=$ssh-user --become --become-user=root remove-node.yaml -e node=node5
```
##### Scale up cluster
Replace `$ssh-user` with your real user to ssh to servers
```
cd kubespray
ansible-playbook -i ../cluster/homelab-k8s/hosts.yaml -e @../cluster/homelab-k8s/cluster-config.yaml --user=$ssh-user --become --become-user=root scale.yaml --limit=node5
```

#### 5. Get kubeconfig
First ssh to `10.0.0.102` server ( node1 ). Then:

Verify that cluster successfully established
```
sudo su -
kubectl get nodes
kubectl -n kube-system get pods
```
#### 6. Deploy workloads
#### 7. Destroy infrastructure
```
terraform destroy --auto-approve
```
