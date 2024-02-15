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
export TF_VAR_ssh_key="$value"
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
##### Clone kubespray repository
```
git clone https://github.com/kubernetes-sigs/kubespray.git
```

##### Install Ansible
```
cd kubespray
pip install -U -r requirements.txt
```

##### Update pip

```
python3 -m pip install --upgrade pip
```

##### Create host inventory
Why `102`, `103`, `104`. It is internal ip addresses of server defined in `compute-instance.tf`
```
declare -a IPS=(10.0.0.102 10.0.0.103 10.0.0.104)
cd ../ 
mkdir -p cluster/homelab-k8s
CONFIG_FILE=cluster/homelab-k8s/hosts.yaml python3 kubespray/contrib/inventory_builder/inventory.py ${IPS[@]}
```

##### Create cluster config
```
cat << EOF | sudo tee -a /home/$USER/homelab/kubernetes/cluster/homelab-k8s/cluster-config.yaml
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
```
vi cluster/homelab-k8s/cluster-config.yaml
```
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
```
cd kubespray
ansible-playbook -i ../cluster/homelab-k8s/hosts.yaml -e @../cluster/homelab-k8s/cluster-config.yaml --user=$USER --become --become-user=root cluster.yml
```
Output:

```
Thursday 15 February 2024  04:18:43 +0000 (0:00:00.256)       0:14:24.910 *****
===============================================================================
download : Download_file | Download item ----------------------------------------------------------------------------------------------------------------------------------------------------------- 71.72s
bootstrap-os : Install libselinux python package --------------------------------------------------------------------------------------------------------------------------------------------------- 53.74s
kubernetes/preinstall : Install packages requirements ---------------------------------------------------------------------------------------------------------------------------------------------- 48.34s
download : Download_file | Download item ----------------------------------------------------------------------------------------------------------------------------------------------------------- 38.68s
download : Download_file | Download item ----------------------------------------------------------------------------------------------------------------------------------------------------------- 24.34s
etcd : Reload etcd --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 21.30s
kubernetes/kubeadm : Join to cluster --------------------------------------------------------------------------------------------------------------------------------------------------------------- 20.00s
kubernetes/control-plane : Kubeadm | Initialize first master --------------------------------------------------------------------------------------------------------------------------------------- 11.68s
etcd : Gen_certs | Write etcd member/admin and kube_control_plane client certs to other etcd nodes ------------------------------------------------------------------------------------------------- 10.76s
container-engine/containerd : Download_file | Download item ---------------------------------------------------------------------------------------------------------------------------------------- 10.46s
container-engine/runc : Download_file | Download item ---------------------------------------------------------------------------------------------------------------------------------------------- 10.31s
container-engine/nerdctl : Download_file | Download item ------------------------------------------------------------------------------------------------------------------------------------------- 10.14s
container-engine/crictl : Download_file | Download item -------------------------------------------------------------------------------------------------------------------------------------------- 10.09s
etcdctl_etcdutl : Download_file | Download item ----------------------------------------------------------------------------------------------------------------------------------------------------- 9.00s
kubernetes-apps/ansible : Kubernetes Apps | Lay Down CoreDNS templates ------------------------------------------------------------------------------------------------------------------------------ 7.47s
container-engine/crictl : Extract_file | Unpacking archive ------------------------------------------------------------------------------------------------------------------------------------------ 7.25s
kubernetes-apps/ansible : Kubernetes Apps | Start Resources ----------------------------------------------------------------------------------------------------------------------------------------- 6.93s
etcdctl_etcdutl : Extract_file | Unpacking archive -------------------------------------------------------------------------------------------------------------------------------------------------- 6.75s
container-engine/nerdctl : Extract_file | Unpacking archive ----------------------------------------------------------------------------------------------------------------------------------------- 6.53s
etcd : Gen_certs | Gather etcd member/admin and kube_control_plane client certs from first etcd node ------------------------------------------------------------------------------------------------ 6.50s
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
