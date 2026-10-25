# Changelog

Versions are Git tags; `./k8s/update` offers the latest one. Read the entries between
your installed version (`./k8s/deploy --version`) and the one you install.

## 2.5.0

- `beforeDeploy` hooks receive the requested image tag as `IMAGE_TAG`, empty when
  deploy was run without one, so one hook can build what the deploy will run.

## 2.4.0

- Add `beforeDeploy`, a local command and argument list run before Helm deployment.
  Hooks run relative to deployments.yaml, support defaults and deployment overrides,
  stop deployment on failure, and are skipped by preview and dry-run.

## 2.3.0

- Update prints a suggested commit command using the selected tag or branch.

## 2.2.0

- Add `helmArgs` to defaults and deployments for recurring deploy and preview options.
  Deployment lists replace defaults; an empty list or null clears inherited arguments.
  CLI scalar options take precedence; repeatable options accumulate using Helm's rules.
  Configured arguments pass through the same validation as CLI arguments.

## 2.1.0

- Deploy and preview now set timestamped appVersion values by default, like `--restart`.
  Set `restart: false` in defaults or a deployment to disable this behavior, or use
  `--no-restart` for one run. `--restart` overrides the configured setting.

## 2.0.0

A rewrite with the same commands and Git layout. New: config validation, secrets
set|edit|rekey, preview --diff, status|history|rollback|logs|exec, list|config|doctor|
init|install|update, and shell completion. Read every point before updating:

- install and update download a release tarball from GitHub instead of merging a Git
  subtree over SSH, into the directory they are run from (usually k8s) rather than the
  Git root; an existing subtree copy is replaced in place on the next update.
- Deploy tracks the rollout after Helm returns, as before; track_helm_deployment is no
  longer a standalone command. build_dockerconfigjson and kubeconfig.template are removed.
- Only deploy, kubectl, attach and secrets are linked beside k8s-tools; every other
  command runs as ./k8s-tools/NAME, and ./k8s-tools/symlink-commands NAME adds links.
- Rename environments to deployments. Existing deployment names can stay.
- createNamespace defaults to false; enable it explicitly where required.
- Configure a context/kubeconfig or explicitly allow useCurrentContext.
- Charts receive plaintext values under secrets.<name>.data. Decryption happens
  in the tool; encryptionKey is not passed to the chart.
- Old Helm revisions retain their previous values, including encryption keys.
  Rotate the key if historical copies should no longer decrypt newly encrypted values.
- Image tags are optional; appVersion timestamps and empty resourcePrefix overrides
  are no longer injected. Use --restart or an explicit override when intended.
- Extra Helm arguments no longer disable rollout tracking. Use --no-wait.
- Quoted forwarded arguments stay intact. Attach uses sh by default and refuses
  ambiguous matches.
- VAULT_SECRETS/read-vault-secrets.sh are no longer sourced. Supply needed environment
  variables directly.
- load_environment_config was renamed load_deployment_config. It and the new sourced
  helpers are internal shell interfaces; custom scripts must explicitly request
  require_cluster/require_chart/require_release/require_encryption_key as needed.
- Legacy configuration paths still work. Opt into schemaVersion 2 separately:
  move common release/repo/chart/version into defaults and prefix values paths with
  values/ where needed.

## 1.8.1

- `createNamespace: false` set per environment is honored.

## 1.8.0

- `keyFile` is replaced by `keyRef` with a scheme: `file://keys/main.key` or
  `axo://vault/secret-id/key`. Update `deployments.yaml` before deploying.
- The key is quoted in the generated values, so numeric-looking passphrases stay strings.

## 1.7.0

- Optional `keyRef` reads the encryption key from Axo Pass on each deploy; only deploy
  and secrets ask for it. The key is no longer passed as a command argument.
