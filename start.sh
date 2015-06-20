#!/bin/bash
export API_HOST=10.1.2.3
export DOCKER_HOST_ORIGINAL="${DOCKER_HOST}"
export DOCKER_HOST="tcp://${API_HOST}:2375"
export DOCKER_TLS_VERIFY_ORIGINAL="${DOCKER_TLS_VERIFY}"
export DOCKER_TLS_VERIFY=
export DOCKER_CERT_PATH_ORIGINAL="${DOCKER_CERT_PATH}"
export DOCKER_CERT_PATH=
export DOCKER_NATIVE_ORIGINAL="${DOCKER_NATIVE}"
export DOCKER_NATIVE=true
export KUBERNETES_MASTER_ORIGINAL="${KUBERNETES_MASTER}"
export KUBERNETES_MASTER="${API_HOST}:8080"

KUBE_ROOT="~/gopath/src/github.com/GoogleCloudPlatform/kubernetes"

# For convenience.
alias pushk="pushd ${KUBE_ROOT}"
alias killk="ps axu | grep -e go/bin -e etcd | grep -v grep | awk '{ print \$2 }' | xargs kill"
alias kstart="( cd ${KUBE_ROOT} && killk; hack/local-up-cluster.sh )"
