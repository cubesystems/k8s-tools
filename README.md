# Kubernetes and Helm deployment scripts

Project-local Bash commands for Helm deployments, encrypted values and day-to-day
cluster work. Needs Bash 3.2+, Helm 3.14+ or 4.x, kubectl, Mike Farah's yq v4, jq and curl.

## Setup and updates

From the directory that holds your deployment configuration, usually k8s in the project:

~~~shell
cd k8s
curl -fsSL https://raw.githubusercontent.com/cubesystems/k8s-tools/master/install | bash
./k8s-tools/init
~~~

Set your chart and Kubernetes context in deployments.yaml, then:

~~~shell
./k8s-tools/doctor test
./deploy test
~~~

The tools are plain files in k8s-tools; deploy, kubectl, attach and secrets are linked
beside it and the rest run as `./k8s-tools/NAME`. `./k8s-tools/symlink-commands logs exec`
links more. Commit it all like any other files. `curl ... | bash -s -- DIRECTORY` installs
elsewhere. `./k8s-tools/update` offers the latest release and accepts another tag or
branch at the prompt or as `K8S_TOOLS_REF`. Both download public tarballs from GitHub;
no Git access or credentials are involved. k8s-tools/REVISION records the installed tag
and date. See CHANGELOG.md for what changed.

The examples below run from that directory. Commands accept `--help`, `--version`
and a leading `--config FILE`; otherwise deployments.yaml is found beside the command
or in the current directory and its ancestors.

## Configuration

~~~yaml
# yaml-language-server: $schema=./k8s-tools/deployments.schema.json
schemaVersion: 2
defaults:
  release: my-application
  repo: https://cubesystems.github.io/charts
  chart: laravel
  version: "2.0.0"
  context: my-cluster
  timeout: 5m
  keyRef: axo://my-application/k8s/main-key

deployments:
  test:
    namespace: my-app-test
    values:
      - values/groups/all.yaml
      - values/environments/test.yaml
  production:
    namespace: my-app-production
    context: production-cluster
    keyRef: axo://my-application/k8s/production-key
    values:
      - values/groups/all.yaml
      - values/environments/production.yaml
~~~

Every setting may be shared under defaults or set on a deployment:

| Setting | Meaning |
| --- | --- |
| release | Helm release name; required for deployment and release commands |
| namespace | Kubernetes namespace; required for cluster operations and rendering |
| chart | Chart name with repo, a local path, an OCI reference, or a Helm repository alias |
| repo | Optional HTTP chart repository URL |
| version | Optional chart version; pin remote charts for reproducible deployments |
| values | Ordered list of values files; optional |
| context | Named kubeconfig context |
| kubeconfig | Optional kubeconfig file |
| useCurrentContext | Explicit permission to use the current context when no connection is configured |
| keyRef | Encryption key reference; optional when DEPLOY_ENCRYPTION_KEY supplies the key |
| createNamespace | Create a missing namespace during install; defaults to false |
| timeout | Rollout tracking deadline and Helm timeout; defaults to 5m |
| imageTagPath | Mapping path set by an image tag argument; defaults to image.tag |
| resourcePrefix | Optional value passed to the chart; no implicit suffix |

A deployment's values list replaces the default list. Relative paths resolve against
deployments.yaml; files without `schemaVersion` keep the 1.x layout with top-level
settings and paths relative to the values directory. Unknown fields fail by name.

~~~shell
./k8s-tools/list
./k8s-tools/config show production
./k8s-tools/config validate
./k8s-tools/doctor production
./k8s-tools/doctor --cluster production
~~~

None of these touch the cluster except `doctor --cluster`, which checks that the
selected identity can get pods.

## Deploying and previewing

~~~shell
./deploy production --image-tag v1.2.0
./deploy production v1.2.0
./deploy production --timeout 10m
./deploy production --no-wait
./deploy production --set-string 'configuration.message=hello world'
./k8s-tools/preview production --image-tag v1.2.0
./k8s-tools/preview production --image-tag v1.2.0 --diff
~~~

- The image tag is optional and sets only imageTagPath. `--restart` sets a timestamped
  appVersion for charts that use it to roll pods.
- After Helm returns, deploy follows each workload's rollout and waits for Jobs until
  the timeout, and fails if one fails. `--no-wait` returns right after Helm.
- Other Helm arguments are forwarded as given, quoting included.
- The target context, namespace, release and chart are printed first. Context is
  passed per command and never changes your current kubeconfig context.

Preview renders locally with the same values as deploy, with secrets redacted.
`--diff` compares against the installed release and reports secret changes by name.
Deploy's `--dry-run` runs the same preview.

## Daily operations

~~~shell
./k8s-tools/status production
./k8s-tools/history production
./k8s-tools/rollback production 4
./k8s-tools/logs production deployment/web -f -c app
./k8s-tools/exec production deployment/web -c app -- sh
./attach production web-abc123 sh
./kubectl production get pods
~~~

All resolve the same release and cluster as deploy. Logs and exec can omit the resource
when the release has exactly one workload. Attach takes an exact pod name or an
unambiguous substring.

Deployment-name completion:

~~~shell
source <(./k8s-tools/completion bash)
# or, in zsh after compinit:
source <(./k8s-tools/completion zsh)
~~~

## Connection and CI variables

Laptops and CI follow the same rules:

- Context: command override, then DEPLOY_KUBE_CONTEXT, then the configured context.
- Credentials: DEPLOY_KUBECONFIG, then the server/token pair, then the configured
  kubeconfig file, then standard kubectl configuration.
- DEPLOY_KUBE_CONTEXT is set only in CI, where the GitLab agent provides the cluster
  connection and the kubeconfig files used on laptops do not exist. With it set, a
  configured kubeconfig file is ignored and the runner's own configuration is used.
- With nothing configured, `useCurrentContext: true` is required; the refusal names
  the current context so it can be copied into deployments.yaml.

| Variable | Meaning |
| --- | --- |
| DEPLOY_KUBE_CONTEXT | Context override, including GitLab agent contexts |
| DEPLOY_KUBECONFIG | Full kubeconfig contents |
| DEPLOY_KUBECTL_SERVER_URL / DEPLOY_KUBECTL_TOKEN | API server URL and token; both required together |
| DEPLOY_ENCRYPTION_KEY | Encryption key override; read only when encryption/decryption needs it |
| DEPLOY_RELEASE | Selected deployment's release override |
| DEPLOY_TIMEOUT | Default wait timeout override |
| DEPLOY_RESOURCE_PREFIX | Legacy prefix override; a nonempty value gets a trailing hyphen |

## Secrets

Values stay encrypted in Git in the HELM_SECRET format and are decrypted locally
before Helm runs. The chart receives plain values and never the key.

~~~yaml
secrets:
  app-config:
    data:
      DB_PASSWORD: HELM_SECRET:...
~~~

### Key sources

~~~yaml
defaults:
  keyRef: axo://my-application/k8s/main-key   # Axo Pass: vault / secret ID / key
~~~

~~~yaml
defaults:
  keyRef: file://keys/main.key                # local file, relative to deployments.yaml
~~~

Keep key files out of Git. CI supplies DEPLOY_ENCRYPTION_KEY instead of a keyRef.

### Setting and editing values

~~~shell
./secrets set production values/production.yaml --secret app-config --key DB_PASSWORD
./secrets edit production values/production.yaml
./secrets edit production
~~~

Without a file, the deployment's only values file is used. Set prompts without echo, or
reads `--stdin`. Edit opens the decrypted secrets in your editor and re-encrypts only
what changed; cancelling or invalid YAML leaves the file untouched.

~~~shell
./secrets encrypt production values/production.yaml --in-place
./secrets decrypt production values/production.yaml
~~~

Encrypt leaves existing ciphertext alone. Decrypt prints plaintext to stdout.

### Rekeying

Create the new key first, then:

~~~shell
./secrets rekey production --to-key-ref axo://my-application/k8s/production-key-v2
./secrets rekey staging production --to-key-ref file://keys/new.key
~~~

Name every deployment that shares a values file. Rekey prints the path of an encrypted
recovery journal; `./secrets recover PATH` restores the previous files if something
went wrong, and refuses files changed since. Update DEPLOY_ENCRYPTION_KEY in CI after.

## Development checks

~~~shell
bash tests/run
~~~

The tests use real local Helm rendering and mocked cluster commands; no cluster is
contacted.
