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
export TF_VAR_projectId=$value
```
Replace `$value` with your real ssh public key
```
export TF_VAR_ssh_key=$value
```
Replace `$value` with your real ssh user
```
export ssh_user=$value
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
From local to server:
```
rsync -avz -e "ssh -i ~/.ssh/id_rsa" ~/.ssh/id_rsa $ssh_user@destination_server:/home/$ssh_user/.ssh/id_rsa

```
Or:
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
Replace `$ssh_user` with your real user to ssh to servers
```
cd kubespray
ansible-playbook -i ../cluster/homelab-k8s/hosts.yaml -e @../cluster/homelab-k8s/cluster-config.yaml --user=$ssh_user --become --become-user=root upgrade-cluster.yml
```
##### Scale down cluster
Replace `$ssh_user` with your real user to ssh to servers
```
cd kubespray
ansible-playbook -i ../cluster/homelab-k8s/hosts.yaml -e @../cluster/homelab-k8s/cluster-config.yaml --user=$ssh_user --become --become-user=root remove-node.yaml -e node=node5
```
##### Scale up cluster
Replace `$ssh_user` with your real user to ssh to servers
```
cd kubespray
ansible-playbook -i ../cluster/homelab-k8s/hosts.yaml -e @../cluster/homelab-k8s/cluster-config.yaml --user=$ssh_user --become --become-user=root scale.yaml --limit=node5
```

#### 5. Get kubeconfig
Install `rsync` on master:

```
sudo yum install rsync -y
```
Copy `private key` to node1:

Replace `$value` with your real ssh user
```
export ssh_user=$value
rsync -avz -e "ssh -i ~/.ssh/id_rsa" ~/.ssh/id_rsa $ssh_user@10.0.0.102:/home/$ssh_user/.ssh/id_rsa
```

then ssh to `10.0.0.102` server ( node1 ). Then:
```
ssh -i ~/.ssh/id_rsa $USER@10.0.0.102
```

Verify that cluster successfully established

```
sudo su -
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
kubectl get nodes
kubectl -n kube-system get pods
```

```
NAME    STATUS   ROLES           AGE   VERSION
node1   Ready    control-plane   66m   v1.28.1
node2   Ready    control-plane   66m   v1.28.1
node3   Ready    <none>          65m   v1.28.1
```

```
calico-kube-controllers-648dffd99-ckzdw   1/1     Running   0          67m
calico-node-2plbz                         1/1     Running   0          67m
calico-node-7rmtv                         1/1     Running   0          67m
calico-node-tgnng                         1/1     Running   0          67m
coredns-77f7cc69db-252fm                  1/1     Running   0          67m
coredns-77f7cc69db-4jz7m                  1/1     Running   0          67m
dns-autoscaler-8576bb9f5b-k6xmr           1/1     Running   0          67m
kube-apiserver-node1                      1/1     Running   1          69m
kube-apiserver-node2                      1/1     Running   1          69m
kube-controller-manager-node1             1/1     Running   2          69m
kube-controller-manager-node2             1/1     Running   2          68m
kube-proxy-kzgln                          1/1     Running   0          68m
kube-proxy-nckjx                          1/1     Running   0          68m
kube-proxy-vr87b                          1/1     Running   0          68m
kube-scheduler-node1                      1/1     Running   1          69m
kube-scheduler-node2                      1/1     Running   1          68m
nginx-proxy-node3                         1/1     Running   0          67m
nodelocaldns-6lj8g                        1/1     Running   0          67m
nodelocaldns-b4v5q                        1/1     Running   0          67m
nodelocaldns-hsmfh                        1/1     Running   0          67m
```

Install `rsync`

```
sudo yum install rsync -y

```
Copy kubeconfig to master:

Replace `$value` with your real ssh user
```
export ssh_user=$value
rsync -avz -e "ssh -i /home/$ssh_user/.ssh/id_rsa" ~/.kube/config $ssh_user@10.0.0.101:/home/$ssh_user/.kube/config
```
Check that we can interact with cluster from master:

ssh to master:
```
ssh -i /home/$ssh_user/.ssh/id_rsa $ssh_user@10.0.0.101
```

```
vi ~/.kube/config
```
server: https://127.0.0.1:6443 > server: https://10.0.0.102:6443 

```
sudo su -
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
kubectl get nodes
kubectl -n kube-system get pods
```

Output:
```
NAME    STATUS   ROLES           AGE   VERSION
node1   Ready    control-plane   66m   v1.28.1
node2   Ready    control-plane   66m   v1.28.1
node3   Ready    <none>          65m   v1.28.1
```

```
calico-kube-controllers-648dffd99-ckzdw   1/1     Running   0          67m
calico-node-2plbz                         1/1     Running   0          67m
calico-node-7rmtv                         1/1     Running   0          67m
calico-node-tgnng                         1/1     Running   0          67m
coredns-77f7cc69db-252fm                  1/1     Running   0          67m
coredns-77f7cc69db-4jz7m                  1/1     Running   0          67m
dns-autoscaler-8576bb9f5b-k6xmr           1/1     Running   0          67m
kube-apiserver-node1                      1/1     Running   1          69m
kube-apiserver-node2                      1/1     Running   1          69m
kube-controller-manager-node1             1/1     Running   2          69m
kube-controller-manager-node2             1/1     Running   2          68m
kube-proxy-kzgln                          1/1     Running   0          68m
kube-proxy-nckjx                          1/1     Running   0          68m
kube-proxy-vr87b                          1/1     Running   0          68m
kube-scheduler-node1                      1/1     Running   1          69m
kube-scheduler-node2                      1/1     Running   1          68m
nginx-proxy-node3                         1/1     Running   0          67m
nodelocaldns-6lj8g                        1/1     Running   0          67m
nodelocaldns-b4v5q                        1/1     Running   0          67m
nodelocaldns-hsmfh                        1/1     Running   0          67m
```

#### 6. Deploy workloads
#### 7. Destroy infrastructure
```
terraform destroy --auto-approve
```
