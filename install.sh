#!/usr/bin/env bash

set -ex -o pipefail

kube_version=1.24.4-00
flux_version=0.33.0

usage_error () { echo >&2 "$(basename $0):  $1"; exit 2; }

install_k8s () {
    apt-get update
    apt install curl apt-transport-https vim git wget gnupg2 \
        software-properties-common apt-transport-https ca-certificates uidmap -y
    swapoff -a
    modprobe overlay
    modprobe br_netfilter
    cat << EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
    sysctl --system
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    apt install containerd -y
    echo "deb  http://apt.kubernetes.io/  kubernetes-xenial  main" > /etc/apt/sources.list.d/kubernetes.list
    curl -s \
         https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | apt-key add -
    apt-get update
    apt-get install -y kubeadm=${kube_version} kubelet=${kube_version} kubectl=${kube_version}
    apt-mark hold kubelet kubeadm kubectl
}

install_fluxcd () {
    FLUX_VERSION=${flux_version} curl -s https://fluxcd.io/install.sh | sudo bash
}

boot_fluxcd () {
    local remote=$1
    local env=$2
    local privkey_file=$3
    flux install --namespace=flux-system \
                 --components=source-controller,kustomize-controller,helm-controller,notification-controller \
                 --cluster-domain=azkaban

    flux create secret git flux-system \
         --url=$remote \
         --private-key-file=$privkey_file

    cat > gotk-sync.yaml <<EOF
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: flux-origin
  namespace: flux-system
spec:
  interval: 1m0s
  ref:
    branch: main
  secretRef:
    name: flux-system
  url: ${remote}
---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: flux-origin
  namespace: flux-system
spec:
  interval: 10m0s
  path: ./clusters/${env}
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-origin
EOF
    kubectl apply -f gotk-sync.yaml

}

init_cp () {
    local cp_ip=$1
    local cp_hostname=$2
    local node_ip=$3
    local node_hostname=$4
    local podnet_cidr=$5
    local podnet_cidr_re=${podnet_cidr/\//\\\/}
    local svcnet_cidr=$6
    local svcnet_dns_ip=$7
    local token=$8
    curl -fsSL -O https://docs.projectcalico.org/manifests/calico.yaml
    perl -0pe "s/(\n.*)# (- name: CALICO_IPV4POOL_CIDR)(\n.*)# (.*)/\1\2\3  value: ${podnet_cidr_re}/" calico.yaml
    cat >> /etc/hosts << EOF
${cp_ip} ${cp_hostname}
${node_ip} ${node_hostname}
EOF
    cat > kubeadm-config.yaml << EOF
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: 1.24.4
controlPlaneEndpoint: "${cp_hostname}:6443"
clusterName: azkaban
networking:
  dnsDomain: azkaban
  serviceSubnet: ${svcnet_cidr}
  podSubnet: ${podnet_cidr}
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${node_ip}
  bindPort: 6443
nodeRegistration:
  name: ${node_hostname}
bootstrapTokens:
- token: "${token}"
  description: "bootstrap token"
  usages:
  - authentication
  - signing
  groups:
  - system:bootstrappers:kubeadm:default-node-token
EOF
    kubeadm init --config=kubeadm-config.yaml --upload-certs
    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    kubectl apply -f calico.yaml
}

join_worker () {
    local cp_ip=$1
    local cp_hostname=$2
    local node_ip=$3
    local token=$4
    local discovery_ca_hash=$5
    cat >> /etc/hosts << EOF
${cp_ip} ${cp_hostname}
EOF
    cat >> kubeadm-config.yaml <<EOF
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
discovery:
  bootstrapToken:
    token: "${token}"
    apiServerEndpoint: "${cp_hostname}:6443"
    caCertHashes:
    - "sha256:${discovery_ca_hash}"
nodeRegistration:
  kubeletExtraArgs:
    node-ip: "${node_ip}"
EOF
    kubeadm join --config kubeadm-config.yaml
}

op=$1; shift

case $op in
    install_k8s) install_k8s;;
    install_fluxcd) install_fluxcd;;
    boot_fluxcd) boot_fluxcd $@ ;;
    init_cp) init_cp $@ ;;
    join_worker) join_worker $@ ;;
    *)  usage_error "unknown operation '${op}'";;
esac
