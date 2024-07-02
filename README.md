# Kubernetes and Helm charts deployment scripts


## Setup
To add k8-tools as subtree to k8s directory:
```shell
git subtree add --prefix=k8s/k8s-tools git@github.com:cubesystems/k8s-tools.git master
cd k8s
./k8s-tools/symlink-commands
```

and commit symlinked commands

## Updating
To updated to latest script version from project root:
```shell
git subtree pull --prefix=k8s/k8s-tools/ git@github.com:cubesystems/k8s-tools.git master --squash
```