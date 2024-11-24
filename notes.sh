# enable Ipv4 packet forwarding

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Install containerd runtime
dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y containerd.io

# enable containerd
systemctl enable --now containerd

# generate default containerd config
containerd config default | sudo tee /etc/containerd/config.toml

# 1. Enable CRI plugin (if needed)
# 2. Use systemd cgroup driver for containerd

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true # only this one, not the snake_case one

# restart containerd
systemctl restart containerd

# open ports
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=2379/tcp
sudo firewall-cmd --permanent --add-port=2380/tcp
sudo firewall-cmd --permanent --add-port=10250/tcp
sudo firewall-cmd --permanent --add-port=10259/tcp
sudo firewall-cmd --permanent --add-port=10257/tcp
sudo firewall-cmd --reload

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Add kubernetes yum repository
# This overwrites any existing configuration in /etc/yum.repos.d/kubernetes.repo
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# install kubeadm, kubelet, kubectl
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# enable kubelet service
sudo systemctl enable --now kubelet

# init cluster - make sure pod-network-cidr doesn't overlap with host network CIDR
kubeadm init --apiserver-advertise-address=192.168.1.47 --pod-network-cidr=10.244.0.0/16

# set admin conf path
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bashrc

# install network operator (edit CIDR in CDR to match the one used in pod-network-cidr switch)
https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart

