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

## Configuration

### deployments.yaml

The `deployments.yaml` file defines your deployment environments and their configurations.

**Example configuration:**
```yaml
release: my-application
repo: https://cubesystems.github.io/charts
chart: laravel
version: 1.3.9

defaults:
  keyRef: file://keys/main.key  # Where the encryption key is read from

environments:
  test:
    namespace: my-app-test
    kubeconfig: test.kubeconfig.yml  # Optional: local kubeconfig file
    values:
      - groups/all.yaml
      - environments/test.yaml

  production:
    namespace: my-app-production
    kubeconfig: production.kubeconfig.yml
    keyRef: axo://my-application/k8s/production-key  # Override default key for production
    values:
      - groups/all.yaml
      - environments/production.yaml
```

**Configuration options:**

- **`release`**: Helm release name
- **`repo`**: Helm chart repository URL (optional if using local chart)
- **`chart`**: Chart name or path to local chart directory
- **`version`**: Chart version (optional)

**`defaults` section (all optional):**
- **`keyRef`**: Default reference to read the encryption key from (see Secrets Management)
- **`namespace`**: Default namespace for all environments
- **`kubeconfig`**: Default kubeconfig file
- **`createNamespace`**: Whether to create namespace if it doesn't exist (default: true)

**Per-environment options:**
- **`namespace`**: Kubernetes namespace (required unless set in defaults)
- **`kubeconfig`**: Path to kubeconfig file relative to k8s directory (optional)
- **`keyRef`**: Override default encryption key reference for this environment (optional)
- **`values`**: Array of values files to apply (order matters - later files override earlier ones)
- **`createNamespace`**: Override default namespace creation behavior (optional)
- **`repo`**: Override chart repository URL (optional)
- **`chart`**: Override chart name or path (optional)
- **`version`**: Override chart version (optional)

**Important notes:**
- The `defaults` section is entirely optional - you can configure everything per-environment
- Values files are applied in order - later files override values from earlier files
- `kubeconfig` is optional - if not specified, uses your default kubectl context
- `keyRef` is optional - only needed if you're using encrypted secrets
- Environment-specific settings override `defaults` section
- For production, it's recommended to use a separate `keyRef` for enhanced security

## Secrets Management

### Encryption Key Setup

**CI/CD Environment:**
- Set `DEPLOY_ENCRYPTION_KEY` as a CI/CD variable with your encryption key value

**Local Development:**

`keyRef` names where the key comes from, and its scheme decides how it is read. Only `deploy` and
`secrets` read it, so `kubectl` and `attach` never touch the key.

Option 1 (Recommended - [Axo Pass](https://axo.sh)):

```yaml
defaults:
  keyRef: axo://my-application/k8s/main-key
```

The key is read from the vault on each deploy, unlocked by Touch ID, so no plaintext key is kept
on disk. The three segments of the reference are the vault name, the secret ID and the key inside
it - create them in the Axo Pass app in that order. The secret's **ID** is what appears in the
reference; the Name beside it is only a label. The `ap` CLI ships inside the app bundle and is
symlinked to `/usr/local/bin/ap`, so there is nothing separate to install. Check that the
reference resolves:

```shell
ap read axo://my-application/k8s/main-key
```

Option 2 (Key file, for temporary use):

```yaml
defaults:
  keyRef: file://keys/main.key  # relative to the k8s directory; file:///abs/path also works
```

```shell
# Store key in k8s/keys/main.key (already in .gitignore)
echo "your-encryption-key-here" > k8s/keys/main.key
```

An unknown scheme is refused rather than guessed at.

**CI note:** `keyRef` only decides *whether* an environment has a key. In CI the value always
comes from `DEPLOY_ENCRYPTION_KEY`, whatever the scheme says.

⚠️ **Security Note:** Keep local encryption keys only temporarily. Remove them when not actively needed.

### Encrypting Secrets

1. **Add plaintext value** to your values file (e.g., `k8s/values/environments/test.yaml`):
```yaml
secrets:
  app-config:
    data:
      DB_PASSWORD: HELM_SECRET:JRNdJceLHO5TMtXMKOHqfGSJKMwfc91f/kpPyXo5/ZQ=
      FOO: BAR  # New plaintext value to encrypt
```

2. **Generate encrypted value:**
```shell
./k8s/secrets encrypt test k8s/values/environments/test.yaml
```

Output example:
```yaml
---
# Source: helm-encyption/templates/encrypt.yaml
secrets:
  app-config:
    data:
      FOO: HELM_SECRET:LO0eAR2SqudvIA10vGKLoXfJquii5GSS7yCGcEt0YCA=
```

3. **Replace plaintext with encrypted value** in your values file:
```yaml
secrets:
  app-config:
    data:
      DB_PASSWORD: HELM_SECRET:JRNdJceLHO5TMtXMKOHqfGSJKMwfc91f/kpPyXo5/ZQ=
      FOO: HELM_SECRET:LO0eAR2SqudvIA10vGKLoXfJquii5GSS7yCGcEt0YCA=
```

4. **Commit, push, and deploy**

A missing or wrong key surfaces as a helm `unecrypted secret: ...` failure on deploy.

### Decrypting Secrets

To verify encrypted values locally:
```shell
./k8s/secrets decrypt test k8s/values/environments/test.yaml
```

### Security Best Practices

✅ **DO:**
- Use different encryption keys for each environment (dev, staging, production)
- Rotate encryption keys periodically
- Store keys securely in CI/CD secret management
- Use the space-prefix method when setting keys in shell to avoid history
- Remove local key files (`k8s/keys/*.key`) when not actively developing - with an `axo://` keyRef
  there is no key file to remove
- Ensure `k8s/keys/` is in `.gitignore`

❌ **DON'T:**
- Commit encryption keys to version control
- Share encryption keys via insecure channels
- Use the same key across multiple environments
- Keep production keys on local development machines