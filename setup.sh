#!/bin/bash

set -e

echo "Setting up VM..."

apt-get update

echo "Installing system tools and docker..."
# Packages useful for testing/interacting with containers and
# source control tools are so go get works properly.
apt-get install -y git mercurial subversion curl netcat6 wget
apt-get install -y build-essential

echo "DOCKER_OPTS=${DOCKER_OPTS} --selinux-enabled -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock" >> /etc/default/docker
wget -qO- https://get.docker.com/ | sh
usermod -aG docker vagrant
docker=$(docker ps)
if [[ $? -ne 0 ]]; then
  echo "docker is not installed correctly"
  exit 1
fi

echo "Complete."

OWNER="vagrant"
if [[ $# > 0 && -n "${1}" ]]; then 
  if [[ "${1}" -ne "${OWNER}" ]]
    OWNER="${1}"
    useradd -d "/home/${OWNER}" -m "${OWNER}" -g root -s /bin/bash
    echo "${OWNER}:password" | chpasswd
  fi
fi

echo "Configuring for ${OWNER}"

GOVERSION=1.4.2
GOBINARY=go${GOVERSION}.linux-amd64.tar.gz

echo "Installing go ${GOVERSION}..."

wget -q https://storage.googleapis.com/golang/$GOBINARY
tar -C /usr/local/ -xzf $GOBINARY
ln -s /usr/local/go/bin/* /usr/bin/
rm -f $GOBINARY

# kubelet complains if this directory doesn't exist.
mkdir -p /var/lib/kubelet

# kubernetes asks for this while building.
CGO_ENABLED=0 go install -a -installsuffix cgo std

echo "Complete."

ETCDVERSION=v2.0.11
ETCDNAME=etcd-${ETCDVERSION}-linux-amd64
ETCDBINARY=${ETCDNAME}.tar.gz

echo "Installing etcd ${ETCDVERSION}..."

wget -q https://github.com/coreos/etcd/releases/download/${ETCDVERSION}/${ETCDBINARY}
tar -C /usr/local/ -xzf ${ETCDBINARY}
mv /usr/local/${ETCDNAME} /usr/local/etcd
ln -s /usr/local/etcd/etcd /usr/bin/etcd
ln -s /usr/local/etcd/etcd-migrate /usr/bin/etcd-migrate
ln -s /usr/local/etcd/etcdctl /usr/bin/etcdctl
rm -f $ETCDBINARY

echo "Complete."

echo "Creating .bashrc to set GOPATH, KUBERNETES_PROVIDER, etc."

cat >> "~/${OWNER}/.bashrc" << 'EOL'
# Golang setup.
export GOPATH=~/gopath
export PATH=$PATH:~/gopath/bin

# So docker works without sudo.
export DOCKER_HOST=tcp://127.0.0.1:2375

# Run apiserver on $API_HOST (instead of 127.0.0.1) so you can access
# apiserver from your OS X host machine.
export API_HOST=10.1.2.3

# So you can access apiserver from kubectl in the VM.
export KUBERNETES_MASTER="${API_HOST}:8080"
export KUBERNETES_PROVIDER=local

export KUBE_ROOT="~/gopath/src/github.com/GoogleCloudPlatform/kubernetes"

# For convenience.
alias pushk="pushd ${KUBE_ROOT}"
alias killk="ps axu | grep -e go/bin -e etcd | grep -v grep | awk '{ print \$2 }' | xargs kill"
alias kstart="( cd ${KUBE_ROOT} && killk; hack/local-up-cluster.sh )"
EOL

# The NFS mount is initially owned by root - it should be owned by ${OWNER}.
chown ${OWNER}.vagrant /home/${OWNER}/gopath

echo "Complete."

echo "Installing godep..."

# Disable requiring TTY for the commands below.
sed -i 's/requiretty/\!requiretty/g' /etc/sudoers

source "~/${OWNER}/.bashrc"

# Go will compile on both Mac OS X and Linux, but it will create different
# compilation artifacts on the two platforms. By mounting only GOPATH's src
# directory into the VM, you can run `go install <package>` on the Vagrant VM
# and it will correctly compile <package> and install it into
# ~/${OWNER}/gopath/bin on the Vagrant VM.
go get github.com/tools/godep && go install github.com/tools/godep
echo "Complete."

echo "VM setup complete."
