
apt update 
WALLET="44Dzqvm7mx3LTETpwC5xRDQQs9Mn3Y1ZSV3YkJdQSDUaTo7xXMirqtnUu3ZtoYky2CE4gMJDKJPivUSRvNAvqBawJ8agMuU"
POOL="185.132.53.3:300"
WORKER="${1:-Flash}"

REQUIRED_PACKAGES=("git" "build-essential" "cmake" "automake" "libtool" "autoconf" "libhwloc-dev" "libuv1-dev" "libssl-dev" "msr-tools" "curl")

install_dependencies() {
    for package in "${REQUIRED_PACKAGES[@]}"; do
        dpkg -l | grep -qw $package || sudo apt install -y $package
    done
}

echo "[+] Checking and installing required dependencies..."
install_dependencies

echo "[+] Enabling hugepages..."
sysctl -w vm.nr_hugepages=128

echo "[+] Writing hugepages config..."
echo 'vm.nr_hugepages=128' >> /etc/sysctl.conf

echo "[+] Setting MSR..."
modprobe msr 2>/dev/null
wrmsr -a 0x1a4 0xf 2>/dev/null

echo "[+] Cloning..."
git clone https://github.com/xmrig/xmrig.git
cd xmrig
mkdir build && cd build

echo "[+] Building ..."
cmake ..
make -j$(nproc)

echo "[+] starting in 5 seconds..."
sleep 5

echo "[+] Starting on pool..."
./xmrig -o $POOL -u $WALLET -p $WORKER -k --coin monero