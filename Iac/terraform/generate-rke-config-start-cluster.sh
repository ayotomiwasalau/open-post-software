#!/bin/bash

# Get instance IPs from AWS
echo "Getting instance information..."

# Get the Auto Scaling Group name
ASG_NAME="rantzapp-asg"
AWS_PROFILE="manager"
AWS_REGION="eu-west-1"

# Get instance IDs from the Auto Scaling Group
INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $ASG_NAME \
  --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
  --output text \
  --profile $AWS_PROFILE \
  --region $AWS_REGION)

echo "Found instances: $INSTANCE_IDS"

# Get public and private IPs
NODE1_ID=$(echo $INSTANCE_IDS | awk '{print $1}')
NODE2_ID=$(echo $INSTANCE_IDS | awk '{print $2}')
# NODE3_ID=$(echo $INSTANCE_IDS | awk '{print $3}')

NODE1_IP=$(aws ec2 describe-instances --instance-ids $NODE1_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --profile $AWS_PROFILE --region $AWS_REGION)
NODE1_INTERNAL_IP=$(aws ec2 describe-instances --instance-ids $NODE1_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text --profile $AWS_PROFILE --region $AWS_REGION)

NODE2_IP=$(aws ec2 describe-instances --instance-ids $NODE2_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --profile $AWS_PROFILE --region $AWS_REGION)
NODE2_INTERNAL_IP=$(aws ec2 describe-instances --instance-ids $NODE2_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text --profile $AWS_PROFILE --region $AWS_REGION)

# NODE3_IP=$(aws ec2 describe-instances --instance-ids $NODE3_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
# NODE3_INTERNAL_IP=$(aws ec2 describe-instances --instance-ids $NODE3_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)

echo "Node 1: $NODE1_IP ($NODE1_INTERNAL_IP)"
echo "Node 2: $NODE2_IP ($NODE2_INTERNAL_IP)"
# echo "Node 3: $NODE3_IP ($NODE3_INTERNAL_IP)"

# Generate RKE config
cat > rke-cluster.yml << EOF
nodes:
# Control Plane + etcd nodes (first 2 nodes)
- address: $NODE1_IP
  internal_address: $NODE1_INTERNAL_IP
  user: ec2-user
  role: [controlplane, etcd, worker]
  ssh_key_path: ./ec2-kp.pem

- address: $NODE2_IP
  internal_address: $NODE2_INTERNAL_IP
  user: ec2-user
  role: [controlplane, etcd, worker]
  ssh_key_path: ./ec2-kp.pem

services:
  etcd:
    snapshot: true
    creation: 6h
    retention: 24h

network:
  plugin: canal
  options:
    canal_flannel_backend_type: vxlan

authentication:
  strategy: x509

authorization:
  mode: rbac

ignore_docker_version: false

kubernetes_version: v1.24.10-rancher4-1

cluster_name: rantzapp-cluster

private_registries:
- url: index.docker.io
  user: ""
  password: ""
  is_default: true

# High availability settings
control_plane:
  max_pods: 110

worker:
  max_pods: 110
EOF

echo "RKE configuration generated: rke-cluster.yml" 

rke up --config rke-cluster.yml --ignore-docker-version

base64 -w 0 kube_config_rke-cluster.yml > kube_config_rke-cluster.yml.base64

echo "Kubeconfig base64 encoded: kube_config_rke-cluster.yml.base64"