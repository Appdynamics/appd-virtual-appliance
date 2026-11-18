# Capture VA upgrade credentials

Saves service credentials from a running VA into encrypted configuration before
upgrading a release earlier than 26.10. Run this before stopping services.

## Requirements

Run as a user who can read Kubernetes Secrets, decrypt the existing configuration
with its GPG key, and write to `/var/appd/config`. The VA must provide Python 3,
`sops`, `yq`, `sha256sum`, and `microk8s.kubectl` or `kubectl`.

## Usage

Copy `capture-upgrade-credentials.tar` to the source VA, then run:

```bash
tar -xf capture-upgrade-credentials.tar
cd capture-upgrade-credentials
sh run.sh
```

The default configuration file is `/var/appd/config/secrets.yaml.encrypted`.
To capture into a different encrypted file:

```bash
sh run.sh /path/to/secrets.yaml.encrypted
```

To select a Kubernetes executable:

```bash
sh run.sh --kubectl /snap/bin/microk8s.kubectl
```

Wait for successful completion, then follow the normal VA stop, platform backup,
upgrade and restore procedure. Include the updated encrypted configuration in
the platform backup.

## Output

The tool updates the encrypted configuration and keeps a timestamped encrypted
copy beside it with `.before-capture-<timestamp>` appended to the filename.
It does not print credential values, reset passwords, or change Kubernetes
Secrets. If required credentials are missing or conflict with saved values,
it stops without updating the configuration. Reconcile any unapplied plaintext
`secrets.yaml` before running.

## Upgrade requirements

For a local Controller on 26.7, verify
`mysql.secret.legacyControllerDBPassword` before upgrading: when empty, the tool
assumes the shipped default rather than checking the live database. Correct it
in encrypted configuration if the database password was customized. The target
release must support the Controller database password migration before the
upgraded Controller is started.

Use a 26.10 target release that supports `es.auth.legacyAdminPasswordHash` to
retain an Elasticsearch administrator credential stored only as a bcrypt hash.
If Kafka metrics TLS is not deployed, its optional keystore password is skipped.
