#!/usr/bin/env bash
set -e   # exit on any error

# remote server config
REMOTE_USER="user"
REMOTE_HOST="ip"
REMOTE_PORT="port"

### local paths
LOCAL_LEDGER_DIR="/mnt/nvme/ledger"
LOCAL_KEY_DIR="/home/user/secret"
LOCAL_TOWER_FILE="${LOCAL_LEDGER_DIR}/tower-1_9-1KXvrkPXwkGF6NK1zyzVuJqbXfpenPVPP6hoiK9bsK3.bin"
# local binary
LOCAL_VALIDATOR_BIN="agave-validator"
# identity files
LOCAL_FAKE_ID="${LOCAL_KEY_DIR}/fakeid.json"
LOCAL_ID_SYMLINK="${LOCAL_KEY_DIR}/identity.json"


### remote paths
REMOTE_LEDGER_DIR="/mnt/nvme/ledger"
REMOTE_KEY_DIR="/home/user/secret"
# remote binary
REMOTE_VALIDATOR_BIN="/home/user/clients/agave/target/release/agave-validator"

# identity files
REMOTE_VALIDATOR_ID="${REMOTE_KEY_DIR}/validator.json"
REMOTE_ID_SYMLINK="${REMOTE_KEY_DIR}/identity.json"

# wait for restart window locally
"${LOCAL_VALIDATOR_BIN}" \
  -l "${LOCAL_LEDGER_DIR}" \
  wait-for-restart-window \
  --min-idle-time 2 \
  --skip-new-snapshot-check

# set fake identity locally and update symlink
"${LOCAL_VALIDATOR_BIN}" \
  -l "${LOCAL_LEDGER_DIR}" \
  set-identity "${LOCAL_FAKE_ID}"
ln -sf "${LOCAL_FAKE_ID}" "${LOCAL_ID_SYMLINK}"

# copy tower file, remotely set identity + symlink
scp -P "${REMOTE_PORT}" \
  "${LOCAL_TOWER_FILE}" \
  "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_LEDGER_DIR}" \
&& ssh -p "${REMOTE_PORT}" "${REMOTE_USER}@${REMOTE_HOST}" \
  " \
    '${REMOTE_VALIDATOR_BIN}' \
      -l '${REMOTE_LEDGER_DIR}' \
      set-identity --require-tower '${REMOTE_VALIDATOR_ID}' \
    && ln -sf '${REMOTE_VALIDATOR_ID}' '${REMOTE_ID_SYMLINK}' \
  "
