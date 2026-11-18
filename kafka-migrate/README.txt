VA Kafka upgrade preparation

Prepares a running source VA for upgrade to 26.7 or 26.10:
  25.10: migrates ZooKeeper to KRaft and saves Kafka identity.
  26.1 / 26.7: saves the existing KRaft identity without migrating Kafka.

REQUIREMENTS
Run on a Linux AMD64 VA node with Python 3, MicroK8s, appdctl, sha256sum,
and the appduser account. Keep Kafka and Strimzi running; on 25.10 keep
ZooKeeper running too. The 25.10 source requires Strimzi 0.45.1 and Kafka 3.9.1.
Quiesce application writes and pause service start/sync operations before running.

USAGE
Copy kafka-migrate.tar to the source VA, then run before stopping services:

  tar -xf kafka-migrate.tar
  cd kafka-migrate
  sudo bash run.sh run
  sudo bash run.sh verify

The tool detects the source release automatically. Both commands must succeed
before continuing with the documented VA stop, backup and upgrade procedure.

OUTPUT AND BACKUP
Kafka identity: /var/appd/config/kafka-identity.json
25.10 migration files: /var/appd/config/zk-kraft-migration/

Include these paths, Kafka Secrets, and broker/controller storage in the
platform backup. The identity file alone is not a data backup. Use a target
release with Kafka identity restoration support. When moving data disks to
new VMs, follow the VA procedure for restoring local PV node affinity.

On 25.10, KRaft finalization cannot be rolled back to ZooKeeper. The tool
archives and removes ZooKeeper claims after migration; broker and controller
claims are retained. Allow free space for the ZooKeeper archives. Do not
restart the old ZooKeeper-based Kafka chart after finalization.

OTHER COMMANDS
  sudo bash run.sh check     # Check the running source
  sudo bash run.sh status    # Show saved state and resources

If a command fails, keep services running, resolve the reported error, and
rerun the same command. Do not run multiple copies concurrently. A completed
25.10 migration can be resumed while the original Kafka and Strimzi resources
still exist; storage retention is checked before node pool ownership is linked.
