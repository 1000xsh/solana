#!/bin/bash

if [[ "$1" == "--pubkey" && -n "$2" ]]; then
    PUBKEY=$2
else
    echo "usage: $0 --pubkey <public-key>"
    exit 1
fi

# current epoch
CURRENT_EPOCH=$(solana epoch)

# fetching stake informations
echo "fetching stake information for public key: $PUBKEY"
stake_data=$(solana stakes $PUBKEY --output json)

if [[ -n "$stake_data" ]]; then
    TOTAL_BALANCE=$(echo "$stake_data" | jq '[.[] | .activeStake // 0] | add / 1000000000')
    DELEGATED_STAKE=$(echo "$stake_data" | jq '[.[] | .delegatedStake // 0] | add / 1000000000')
    echo "active stake:    $TOTAL_BALANCE SOL"
    echo "delegated stake: $DELEGATED_STAKE SOL"

    echo "current epoch: $CURRENT_EPOCH"
    # filtering for current and future epochs
    results=$(echo "$stake_data" | jq -r --argjson currentEpoch "$CURRENT_EPOCH" '
        reduce .[] as $stake ({"activations": {}, "deactivations": {}};
            if ($stake.activeStake != null) then
                if ($stake.activationEpoch >= $currentEpoch) then
                    .activations[($stake.activationEpoch|tostring)] += ($stake.activeStake / 1000000000)
                end |
                if ($stake.deactivationEpoch >= $currentEpoch) then
                    .deactivations[($stake.deactivationEpoch|tostring)] += ($stake.activeStake / 1000000000)
                end
            else
                .
            end
        )')

    # display sum
    for epoch in $(echo "$results" | jq -r '.activations | keys[]'); do
        total=$(echo "$results" | jq -r ".activations.\"$epoch\"")
        echo "activation #$epoch: +$total SOL"
    done

    for epoch in $(echo "$results" | jq -r '.deactivations | keys[]'); do
        total=$(echo "$results" | jq -r ".deactivations.\"$epoch\"")
        echo "deactivation #$epoch: -$total SOL"
    done
else
    echo "no stake information found."
fi
