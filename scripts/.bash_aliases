# constants
export BUILD_PATH='/home/frank/firedancer/build/native/gcc/bin/fdctl'
export CONFIG_FILE='/home/frank/firedancer/config.toml'
export SERVICE_NAME='frank'

# aliases
alias fd-logs="sudo journalctl -u $SERVICE_NAME --follow"
alias fd-build="sudo $BUILD_PATH configure init all --config $CONFIG_FILE"
alias fd-restart="sudo systemctl restart $SERVICE_NAME"
alias fd-start="sudo systemctl start $SERVICE_NAME"
alias fd-stop="sudo systemctl stop $SERVICE_NAME"
alias fd-monitor="sudo $BUILD_PATH monitor --config $CONFIG_FILE"
alias fd-ledger="solana-validator --ledger /mnt/ledger monitor"
alias cpuwatch='watch "grep '\''cpu MHz'\'' /proc/cpuinfo"'

# stop, build and start
fd-full-restart() {
    echo "stopping $SERVICE_NAME..."
    if fd-stop; then
        echo "$SERVICE_NAME stopped successfully."
    else
        echo "failed to stop $SERVICE_NAME." >&2
        return 1
    fi

    echo "configuring frank..."
    if fd-build; then
        echo "build completed successfully."
    else
        echo "build failed." >&2
        return 1
    fi

    echo "starting $SERVICE_NAME..."
    if fd-start; then
        echo "$SERVICE_NAME started successfully."
    else
        echo "failed to start $SERVICE_NAME." >&2
        return 1
    fi

    echo "full restart completed successfully."
}

# export the function so it can be used as a command
export -f fd-full-restart
