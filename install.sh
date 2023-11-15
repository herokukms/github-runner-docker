#!/bin/bash
export GIT_CORE_PPA_KEY="A1715D88E1DF1F24"
export GIT_LFS_VERSION="3.2.0"
export TARGET_ARCH="x64"
export DPKG_ARCH="$(dpkg --print-architecture)"
export LSB_RELEASE_CODENAME="$(lsb_release --codename | cut -f2)"
export GH_RUNNER_VERSION="2.311.0"
export DEBIAN_FRONTEND=noninteractive 

cat << EOF > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR=$(lsb_release -i -s 2> /dev/null || echo Debian)
GRUB_CMDLINE_LINUX_DEFAULT=""
GRUB_CMDLINE_LINUX="console=tty1 console=ttyS0,115200"
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --speed=115200"
EOF
update-grub

mkdir -p /opt/hostedtoolcache
mkdir -p /actions-runner

cd /actions-runner || exit

apt -y update
apt -y install --no-install-recommends language-pack-en-base language-pack-en

curl -L "https://github.com/actions/runner/releases/download/v${GH_RUNNER_VERSION}/actions-runner-linux-${TARGET_ARCH}-${GH_RUNNER_VERSION}.tar.gz" | tar -xz

./bin/installdependencies.sh

curl -L http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb > libssl1.1_1.1.0g-2ubuntu4_amd64.deb
sudo dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb
# curl -L http://launchpadlibrarian.net/589816507/libssl1.0.0_1.0.2n-1ubuntu5.8_amd64.deb > libssl1.0.0_1.0.2n-1ubuntu5.8_amd64.deb
# sudo dpkg -i libssl1.0.0_1.0.2n-1ubuntu5.8_amd64.deb
curl -L http://ftp.de.debian.org/debian/pool/main/i/icu/libicu72_72.1-3_amd64.deb > libicu72_72.1-3_amd64.deb
sudo dpkg -i libicu72_72.1-3_amd64.deb
rm -f libssl1.1_1.1.0g-2ubuntu4_amd64.deb
# rm -f libssl1.0.0_1.0.2n-1ubuntu5.8_amd64.deb
rm -f libicu72_72.1-3_amd64.deb

# ./bin/installdependencies.sh

mkdir /_work

chown -R runner /_work /actions-runner /opt/hostedtoolcache

cd /
curl -L https://raw.githubusercontent.com/myoung34/docker-github-actions-runner/master/token.sh > /token.sh
curl -L https://raw.githubusercontent.com/myoung34/docker-github-actions-runner/master/entrypoint.sh > /entrypoint.sh
curl -L https://raw.githubusercontent.com/myoung34/docker-github-actions-runner/master/app_token.sh > /app_token.sh
chmod +x /token.sh /entrypoint.sh /app_token.sh

apt-get clean autoclean
apt-get autoremove --yes
# rm -rf /var/lib/{apt,dpkg,cache,log}/
# rm -rf /var/log/*
# mkdir -p /var/lib/{apt,dpkg,cache,log}/
# mkdir -p /var/lib/dpkg/{alternatives,info,parts,triggers,updates}/
# touch /var/lib/dpkg/status
echo "" > ~/.bash_history
halt