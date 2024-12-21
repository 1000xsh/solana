import glob
import os
import re
from collections import defaultdict

def main():
    # get all log files
    log_files = glob.glob("/mnt/logs/solana-validator.log*")

    # check if exist
    if not log_files:
        print("no log files found in the 'log' directory.")
        return

    # prepare to aggregate lamports by day
    committed_lamports_by_day = defaultdict(int)
    correct_pattern = re.compile(r'num_sanitized_ok.*id=2000|id=2000.*num_sanitized_ok')
    lamports_pattern = re.compile(r"committed_lamports=(\d+)i")
    date_pattern = re.compile(r"\[(\d{4}-\d{2}-\d{2})T")  # matches 'YYYY-MM-DD' in timestamps

    # process each log file
    for log_file in log_files:
        if not os.path.isfile(log_file):
            print(f"file does not exist or is inaccessible: {log_file}")
            continue

        print(f"processing log file: {log_file}")

        try:
            with open(log_file, "r") as f:
                for line in f:
                    # check if the line contains the target pattern
                    if correct_pattern.search(line):
                        # extract lamports
                        lamports_match = lamports_pattern.search(line)
                        if lamports_match:
                            lamports = int(lamports_match.group(1))
                        else:
                            print(f"warning: no 'committed_lamports' found in line: {line.strip()}")
                            continue

                        # extract the date
                        date_match = date_pattern.search(line)
                        if date_match:
                            date = date_match.group(1)  # extract the date part of the timestamp
                        else:
                            date = "unknown date"  # fallback for lines without a date
                            print(f"warning: no date found in line: {line.strip()}")

                        # aggregate lamports by date
                        committed_lamports_by_day[date] += lamports
        except Exception as e:
            print(f"error processing file {log_file}: {e}")

    # display results
    LAMPORTS_PER_SOL = 1_000_000_000
    if committed_lamports_by_day:
        print("\naggregated Lamports by Date:")
        for date, total_lamports in committed_lamports_by_day.items():
            total_sol = total_lamports / LAMPORTS_PER_SOL
            print(f"{date}: {total_sol:.9f} SOL")
    else:
        print("no matching data found in the log files.")

if __name__ == "__main__":
    main()
