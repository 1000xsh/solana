# solana validator leader slot checker

## description
this script checks the upcoming leader slots for a specified solana validator and calculates the time until the next leader slot. it's useful for determining safe periods to perform maintenance activities like restarting the validator without missing important leader slots.

## usage

```bash
chmod + status.sh
```
to use the script, you need to pass the validator identity as an argument.

```bash
./status.sh -i <validator_identity>
```

## packages
install the required package "bs"

```bash
apt install bs -y
```
