#!/bin/bash

BLOCK_ENGINE_URL=https://amsterdam.mainnet.block-engine.jito.wtf
VALIDATORX=your_validator_key

export RUST_LOG=info
export GRPC_BIND_IP=127.0.0.1

export SOLANA_METRICS_CONFIG="host=http://metrics.jito.wtf:8086,db=relayer,u=relayer-operators,p=jito-relayer-write"

exec /sol/jito-relayer-v0.1.14/target/release/jito-transaction-relayer \
          --keypair-path=/sol/relayer-keypair.json \
          --signing-key-pem-path=/sol/sslcerts/private.pem \
          --verifying-key-pem-path=/sol/sslcerts/public.pem \
          --rpc-servers http://127.0.0.1:8899 \
          --forward-all \
          --allowed-validators $VALIDATORX \
          --block-engine-url $BLOCK_ENGINE_URL
