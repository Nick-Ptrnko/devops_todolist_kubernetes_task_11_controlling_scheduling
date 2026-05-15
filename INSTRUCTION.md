# Infrastructure Validation Guide

This guide provides instructions on how to verify the scheduling constraints (Taints, Tolerations, and Affinity rules) implemented in the cluster.

## 1. Verify Node Taints and Labels

Check if the worker nodes have the correct labels and if the MySQL-specific nodes have been tainted correctly.

```bash
# Check labels and taints on all nodes
kubectl get nodes -o custom-columns=NAME:.metadata.name,LABELS:.metadata.labels,TAINTS:.spec.taints

```

**Expected Result:**

* Nodes intended for MySQL should show `app=mysql` in labels and `app=mysql:NoSchedule` in taints.
* Nodes intended for the app should show `app=todoapp` in labels.

## 2. Validate MySQL Scheduling (StatefulSet)

Verify that MySQL pods are running only on the designated nodes and are not sharing the same node.

```bash
# Check MySQL pod distribution
kubectl get pods -n mysql -o wide

```

**Verification Points:**

* **Node Affinity:** Ensure pods are running on nodes with the `app=mysql` label.
* **Tolerations:** Since the nodes are tainted, the fact that pods are `Running` confirms the tolerations are working.
* **Pod Anti-Affinity:** Ensure each MySQL replica is on a different node (check the `NODE` column).

## 3. Validate ToDo App Scheduling (Deployment)

Verify that the application pods prefer the designated app nodes and are spread across the cluster.

```bash
# Check Application pod distribution
kubectl get pods -n todoapp -o wide

```

**Verification Points:**

* **Node Affinity (Preferred):** Pods should ideally be on nodes labeled `app=todoapp`.
* **Pod Anti-Affinity:** Ensure no two application pods are running on the same node to satisfy high availability requirements.

## 4. Deep Inspection of Scheduling Rules

To confirm the rules are present in the pod specification, describe one of the pods:

```bash
# Inspect MySQL Pod
kubectl describe pod mysql-0 -n mysql | grep -A 10 "Affinity:"
kubectl describe pod mysql-0 -n mysql | grep -A 5 "Tolerations:"

# Inspect App Pod
kubectl describe pod -l app=todoapp -n todoapp | grep -A 10 "Affinity:"

```

## 5. Testing the "NoSchedule" Constraint

To verify that the taint actually prevents other pods from landing on MySQL nodes, try to run a temporary pod without tolerations:

```bash
kubectl run test-pod --image=nginx --overrides='{"spec": {"nodeSelector": {"app": "mysql"}}}'
# Check status - it should remain in "Pending"
kubectl get pod test-pod
kubectl describe pod test-pod | grep "Events"

```

**Expected Result:** The pod should fail to schedule with a `Taint` related warning in the events. (Clean up with `kubectl delete pod test-pod`).
