#!/bin/bash

set -ex

# Clean up the ClusterPolicy
oc delete clusterpolicy gpu-cluster-policy --wait=true
while ! oc get pod -n nvidia-gpu-operator -l app.kubernetes.io/component!=gpu-operator | grep -qF 'No resources found'; do
  sleep 5
done

# Clean up the operator
oc delete subscription -n nvidia-gpu-operator gpu-operator-certified --wait=true
oc delete csv -n nvidia-gpu-operator-certified -l operators.coreos.com/gpu-operator-certified.nvidia-gpu-operator --wait=true
while ! oc get pod -n nvidia-gpu-operator | grep -qF 'No resources found'; do
  sleep 5
done

# Install the correct operator
oc apply -f /app/subscription.yaml
while [ "$(oc get subscription -n nvidia-gpu-operator gpu-operator-certified -ojsonpath='{.status.state}')" != "AtLatestKnown" ]; do
  sleep 5
done

# Apply the correct ClusterPolicy
oc apply -f /app/clusterpolicy.yaml
