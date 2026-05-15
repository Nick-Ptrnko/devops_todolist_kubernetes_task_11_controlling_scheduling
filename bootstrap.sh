#!/bin/bash

kind create cluster --config cluster.yml

kubectl taint nodes -l app=mysql app=mysql:NoSchedule

kubectl apply -f .infrastructure/mysql/ns.yml
kubectl apply -f .infrastructure/mysql/configMap.yml
kubectl apply -f .infrastructure/mysql/secret.yml
kubectl apply -f .infrastructure/mysql/service.yml
kubectl apply -f .infrastructure/mysql/statefulSet.yml

kubectl apply -f .infrastructure/app/ns.yml
kubectl apply -f .infrastructure/app/pv.yml
kubectl apply -f .infrastructure/app/pvc.yml
kubectl apply -f .infrastructure/app/secret.yml
kubectl apply -f .infrastructure/app/configMap.yml
kubectl apply -f .infrastructure/app/clusterIp.yml
kubectl apply -f .infrastructure/app/nodeport.yml
kubectl apply -f .infrastructure/app/hpa.yml
kubectl apply -f .infrastructure/app/deployment.yml

echo "Waiting for TodoApp pods to be ready..."
sleep 120

# Install Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Force Ingress Controller to run on the control-plane node
kubectl patch deployment ingress-nginx-controller -n ingress-nginx --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/nodeSelector", "value": {"ingress-ready": "true"}},
  {"op": "add", "path": "/spec/template/spec/tolerations/-", "value": {"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}},
  {"op": "add", "path": "/spec/template/spec/tolerations/-", "value": {"key": "node-role.kubernetes.io/master", "operator": "Exists", "effect": "NoSchedule"}}
]'

echo "Waiting for Ingress Controller pods..."
sleep 120

echo "Applying Ingress rules..."
kubectl apply -f .infrastructure/ingress/ingress.yml
