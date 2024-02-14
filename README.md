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
