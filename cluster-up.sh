#!/bin/bash

# Clean up from last time
rm -fv kubeadm-join

# Initialize the master.
# The API server address is needed because the node has many network interfaces.
# Save the console output, because it contains commands to execute afterwards.
vagrant ssh k8s-master -c "sudo kubeadm init --apiserver-advertise-address 192.168.50.2 > /tmp/kubeadm-init"

# Get the start commands to execute on the master. These are shown after "start using" and start with a blank space.
# Then execute them.
vagrant ssh k8s-master -c "grep --after 4 'start using' /tmp/kubeadm-init | grep '^ ' > /tmp/kubeadm-master-start"
vagrant ssh k8s-master -c "source /tmp/kubeadm-master-start"

# Apply weave network
# https://www.weave.works/docs/net/latest/kubernetes/kube-addon/
# BUG: The worker nodes do not get ready and the weave pods crash
# Maybe there are hints here:
# https://github.com/kubernetes/kubernetes/issues/34101
vagrant ssh k8s-master -c "kubectl apply -f \"https://cloud.weave.works/k8s/net?k8s-version=\$(kubectl version | base64 | tr -d '\n')\""

# Get the join command for the workers
vagrant ssh k8s-master -c "grep 'kubeadm join' /tmp/kubeadm-init" > kubeadm-join

# Execute the join command on the workers
cat kubeadm-join | xargs -I {} vagrant ssh k8s-worker-0 -c "sudo {}"
cat kubeadm-join | xargs -I {} vagrant ssh k8s-worker-1 -c "sudo {}"

# Clean up
rm -fv kubeadm-join
