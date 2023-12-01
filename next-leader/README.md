# solana next leader slot

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
install the required package "bc"

```bash
apt install bc -y
```

## example output
```
./status.sh -i 1KXvrkPXwkGF6NK1zyzVuJqbXfpenPVPP6hoiK9bsK3
your next leader slot is at slot 233200236 (in approximately 0 hours, 25 minutes, 5.2 seconds, and 200.0 milliseconds).
```
