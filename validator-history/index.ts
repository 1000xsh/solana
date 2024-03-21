import { Connection, PublicKey, ConfirmedSignatureInfo } from '@solana/web3.js';
import fs from 'fs';

// const
const RPC_ENDPOINT = 'https://api.mainnet-beta.solana.com';
const VOTE_ACCOUNT_ADDRESS = '1KXz4xKV2viJCGpxqnQqdf2J45vQr5USdmtcJLTaHkm';
const BATCH_SIZE = 1000; 
const RATE_LIMIT_DELAY = 1000;

const connection = new Connection(RPC_ENDPOINT, 'confirmed'); // Use 'confirmed' instead

async function fetchTransactionHistory(): Promise<void> {
    const address = new PublicKey(VOTE_ACCOUNT_ADDRESS);
    let allSignatures: ConfirmedSignatureInfo[] = [];
    let beforeSignature: string | undefined = undefined;

    try {
        // all signatures in batches
        while (true) {
            const signatures = await connection.getConfirmedSignaturesForAddress2(address, {
                before: beforeSignature,
                limit: BATCH_SIZE,
            }, 'confirmed'); // finality

            if (signatures.length === 0) {
                break;
            }

            allSignatures.push(...signatures);
            beforeSignature = signatures[signatures.length - 1].signature;
            console.log(`Fetched ${allSignatures.length} signatures so far`);
            // safe to file after batch size
            fs.writeFileSync('transactions_progress.json', JSON.stringify(allSignatures, null, 2));
            console.log(`progress saved: ${allSignatures.length} signatures so far`);

            // respect the rate limits
            await new Promise(resolve => setTimeout(resolve, RATE_LIMIT_DELAY));
        }

        console.log(`total signatures fetched: ${allSignatures.length}`);

        // final data after fetching all available transactions
        fs.writeFileSync('transactions_final.json', JSON.stringify(allSignatures, null, 2));
        console.log('Final transaction history saved to transactions_final.json');
    } catch (error) {
        console.error('Error fetching transaction history:', error);
    }
}

// Execute the function
fetchTransactionHistory().catch(console.error);
