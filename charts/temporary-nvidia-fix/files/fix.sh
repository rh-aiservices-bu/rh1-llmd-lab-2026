#!/bin/bash

set -e

echo "Removing cluster policy"
oc delete clusterpolicy gpu-cluster-policy --wait=true ||:
echo -n "Waiting for cleanup"
while ! oc get pod -n nvidia-gpu-operator -l app.kubernetes.io/component!=gpu-operator,batch.kubernetes.io/job-name!=fix-gpu-operator |& grep -qF 'No resources found'; do
  echo -n .
  sleep 5
done
echo

echo "Uninstalling the operator"
oc delete subscription -n nvidia-gpu-operator gpu-operator-certified --wait=true ||:
oc delete csv -n nvidia-gpu-operator -l operators.coreos.com/gpu-operator-certified.nvidia-gpu-operator --wait=true ||:
echo -n "Waiting for cleanup"
while ! oc get pod -n nvidia-gpu-operator -l batch.kubernetes.io/job-name!=fix-gpu-operator |& grep -qF 'No resources found'; do
  echo -n .
  sleep 5
done
echo

echo "Installing the new operator"
oc apply -f /app/subscription.yaml
echo -n "Waiting for operator installation"
while [ "$(oc get subscription -n nvidia-gpu-operator gpu-operator-certified -ojsonpath='{.status.state}')" != "AtLatestKnown" ]; do
  echo -n .
  sleep 5
done
echo
echo -n "Waiting for operator pod to be ready"
while [ "$(oc get pod -n nvidia-gpu-operator -l app.kubernetes.io/component=gpu-operator -ojsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}')" != "True" ]; do
  echo -n .
  sleep 5
done
echo

echo "Creating new ClusterPolicy"
oc apply -f /app/clusterpolicy.yaml
