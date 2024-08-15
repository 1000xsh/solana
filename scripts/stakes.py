import requests
from solders.pubkey import Pubkey
import json
from collections import defaultdict
import os
from datetime import datetime, timezone

# rpc
solana_rpc_url = "https://api.mainnet-beta.solana.com"
STATS_FILE = 'stake_stats.json'

# get epoch
def get_current_epoch():
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "getEpochInfo",
    }
    response = requests.post(solana_rpc_url, json=payload)
    return response.json()['result']['epoch']

# get stake acc
def get_stake_accounts_for_vote_pubkey(vote_pubkey):
    filters = [
        {
            "memcmp": {
                "offset": 124,
                "bytes": vote_pubkey
            }
        }
    ]
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "getProgramAccounts",
        "params": [
            str(Pubkey.from_string("Stake11111111111111111111111111111111111111")),
            {
                "encoding": "jsonParsed",
                "filters": filters
            }
        ]
    }
    response = requests.post(solana_rpc_url, json=payload)
    return response.json().get('result', [])

def calculate_stake_metrics(stake_accounts, current_epoch, top_n=10):
    unique_stakers = set()
    unique_accounts = set()
    all_stakers = []
    all_accounts = []
    all_lamports_excluding_current_epoch = 0
    all_lamports_for_current_epoch = 0
    lamports_activating_current_epoch = 0
    lamports_deactivating_current_epoch = 0
    current_epoch_activations = []
    current_epoch_deactivations = []

    for account in stake_accounts:
        pubkey = account['pubkey']
        account_data = account['account']
        lamports = account_data['lamports']
        parsed_data = account_data['data']['parsed']['info']

        staker = parsed_data['meta']['authorized']['staker']
        unique_stakers.add(staker)
        unique_accounts.add(pubkey)
        all_stakers.append(staker)
        all_accounts.append(pubkey)

        activation_epoch = int(parsed_data['stake']['delegation']['activationEpoch'])
        deactivation_epoch = int(parsed_data['stake']['delegation']['deactivationEpoch'])

        if activation_epoch == current_epoch:
            lamports_activating_current_epoch += lamports
            current_epoch_activations.append((pubkey, staker, lamports))
        elif activation_epoch < current_epoch and deactivation_epoch > current_epoch:
            all_lamports_for_current_epoch += lamports

        if deactivation_epoch == current_epoch:
            lamports_deactivating_current_epoch += lamports
            current_epoch_deactivations.append((pubkey, staker, lamports))
        
        if activation_epoch < current_epoch:
            all_lamports_excluding_current_epoch += lamports

    net_stake_change = lamports_activating_current_epoch - lamports_deactivating_current_epoch

    # sort and get top n biggest activation and deactivation wallets
    top_activations = sorted(current_epoch_activations, key=lambda x: x[2], reverse=True)[:top_n]
    top_deactivations = sorted(current_epoch_deactivations, key=lambda x: x[2], reverse=True)[:top_n]

    return {
        'unique_stakers': len(unique_stakers),
        'unique_accounts': len(unique_accounts),
        'all_stakers': len(all_stakers),
        'all_accounts': len(all_accounts),
        'all_lamports_excluding_current_epoch': all_lamports_excluding_current_epoch,
        'all_lamports_for_current_epoch': all_lamports_for_current_epoch,
        'lamports_activating_current_epoch': lamports_activating_current_epoch,
        'lamports_deactivating_current_epoch': lamports_deactivating_current_epoch,
        'net_stake_change': net_stake_change,
        'stake_change_direction': 'positive' if net_stake_change > 0 else 'negative' if net_stake_change < 0 else 'no_change',
        'top_activations': [
            {
                'pubkey': pubkey,
                'staker': staker,
                'lamports': lamports
            } for pubkey, staker, lamports in top_activations
        ],
        'top_deactivations': [
            {
                'pubkey': pubkey,
                'staker': staker,
                'lamports': lamports
            } for pubkey, staker, lamports in top_deactivations
        ]
    }

def update_stats(vote_pubkey):
    current_epoch = get_current_epoch()
    stake_accounts = get_stake_accounts_for_vote_pubkey(vote_pubkey)
    new_metrics = calculate_stake_metrics(stake_accounts, current_epoch)

    current_time = datetime.now(timezone.utc).isoformat()

    if os.path.exists(STATS_FILE):
        with open(STATS_FILE, 'r') as file:
            stats = json.load(file)
    else:
        stats = {'current_stats': {}, 'previous_stats': {}}

    if 'current_stats' in stats and stats['current_stats']:
        stats['previous_stats'] = stats['current_stats']
        stats['previous_stats']['timestamp'] = stats['current_stats'].get('timestamp', 'N/A')

    # update metrics and timestamp
    stats['current_stats'] = new_metrics
    stats['current_stats']['timestamp'] = current_time

    with open(STATS_FILE, 'w') as file:
        json.dump(stats, file, indent=2)

    print(f"updated stats saved to {STATS_FILE}")

# main
if __name__ == "__main__":
    vote_pubkey = "1KXz4xKV2viJCGpxqnQqdf2J45vQr5USdmtcJLTaHkm"
    update_stats(vote_pubkey)
