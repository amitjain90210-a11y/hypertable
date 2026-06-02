#!/usr/bin/env bash
#
# build-setup-ubuntu.sh
#
# Sets up Hypertable build dependencies on Ubuntu 24.04 LTS.
# Must be run as root (or via sudo).
#
# Packages unavailable for Ubuntu 24.04 and their disposition:
#   dstat              - removed from Ubuntu 22.04+; replaced by 'dool' below
#   oprofile           - may be absent from Ubuntu 24.04 universe; 'perf' (linux-tools-generic) is the modern alternative
#   libart-2.0-dev     - deprecated upstream by GNOME; attempted but skipped if absent
#   hyperic-sigar      - project archived ~2016; pre-built x86_64 binary still works,
#                        but no pre-built arm64 binary exists
#   php5 / php5-dev    - PHP 5 is EOL; PHP 8.x installed instead
#   ruby 1.8.7         - EOL; Ruby 3.x installed from apt instead
#   Oracle JDK 6       - replaced by OpenJDK 17 LTS per user request
#   hadoop-0.20        - replaced by Apache Hadoop 3.4.3 per user request
#   xml-commons-apis   - included in JDK 17; no separate package needed
#   Scrooge (Scala)    - SBT + clone from GitHub; may need manual intervention
#                        if the upstream build config has changed

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as root (use sudo)."
  exit 1
fi

# ---------------------------------------------------------------------------
# Architecture detection
# ---------------------------------------------------------------------------
_arch=$(uname -m)
IS_ARM64=0
if [[ "$_arch" == "i386" || "$_arch" == "i586" || "$_arch" == "i686" ]]; then
  ARCH=32
elif [[ "$_arch" == "x86_64" ]]; then
  ARCH=64
elif [[ "$_arch" == "aarch64" ]]; then
  ARCH=64
  IS_ARM64=1
else
  echo "Unsupported architecture: $_arch"
  exit 1
fi

# ---------------------------------------------------------------------------
# 1. Package index + core build tools
# ---------------------------------------------------------------------------
apt-get update

apt-get -y install \
  build-essential \
  g++ \
  make \
  cmake \
  git \
  pkg-config \
  autoconf \
  automake \
  libtool \
  libtool-bin \
  flex \
  bison \
  curl \
  wget \
  zip \
  unzip \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release \
  software-properties-common

# ---------------------------------------------------------------------------
# 2. Core libraries (all from apt — replaces source builds in old scripts)
# ---------------------------------------------------------------------------
apt-get -y install \
  libboost-all-dev \
  libssl-dev \
  libreadline-dev \
  libncurses-dev \
  zlib1g-dev \
  libbz2-dev \
  libexpat1-dev \
  liblog4cpp5-dev \
  libevent-dev \
  libfreetype-dev \
  libpng-dev \
  libpango1.0-dev \
  libcairo2-dev \
  librrd-dev \
  rrdtool \
  libsqlite3-dev \
  libre2-dev \
  libunwind-dev \
  libgoogle-perftools-dev \
  libsnappy-dev \
  libdb5.3-dev \
  libdb5.3++-dev \
  libssh-dev \
  libedit-dev

# libart-2.0-dev is deprecated upstream; install if available, skip if not
apt-get -y install libart-2.0-dev \
  || echo "WARNING: libart-2.0-dev not available in this Ubuntu release; skipping."

# ---------------------------------------------------------------------------
# 3. Java — OpenJDK 17 LTS (replaces Oracle JDK 6)
# ---------------------------------------------------------------------------
apt-get -y install openjdk-17-jdk maven

if [[ "$IS_ARM64" -eq 1 ]]; then
  _java_home=/usr/lib/jvm/java-17-openjdk-arm64
else
  _java_home=/usr/lib/jvm/java-17-openjdk-amd64
fi
cat > /etc/profile.d/java.sh << EOF
export JAVA_HOME=${_java_home}
export PATH=\$PATH:\${JAVA_HOME}/bin
EOF
export JAVA_HOME=${_java_home}
export PATH=${PATH}:${JAVA_HOME}/bin

# Create a stub tools.jar at the path older Maven system dependencies expect
# (tools.jar was removed in Java 9+; this empty stub satisfies the path check).
echo "Manifest-Version: 1.0" > /tmp/MANIFEST.MF
jar cfm /tmp/jdk-tools-stub.jar /tmp/MANIFEST.MF
mkdir -p /usr/lib/jvm/lib
cp /tmp/jdk-tools-stub.jar /usr/lib/jvm/lib/tools.jar

# ---------------------------------------------------------------------------
# 4. Apache Ant (replaces manually installed ant-1.8.2)
# ---------------------------------------------------------------------------
apt-get -y install ant

# ---------------------------------------------------------------------------
# 5. Language runtimes
# ---------------------------------------------------------------------------
# Python 3 (replaces python2-devel)
apt-get -y install python3 python3-dev python3-pip

# Ruby 3.x (replaces Ruby 1.8.7 built from source)
apt-get -y install ruby ruby-dev

# PHP 8.x (replaces php5)
apt-get -y install php php-dev php-cli

# Node.js
apt-get -y install nodejs

# Perl modules
apt-get -y install libbit-vector-perl libclass-accessor-perl

# ---------------------------------------------------------------------------
# 6. Apache Thrift (replaces thrift-0.7.0 built from source)
# ---------------------------------------------------------------------------
apt-get -y install thrift-compiler libthrift-dev python3-thrift ruby-thrift libthrift-perl php-thrift

# ---------------------------------------------------------------------------
# 7. Development and debugging tools
# ---------------------------------------------------------------------------
apt-get -y install \
  doxygen \
  graphviz \
  gdb \
  lldb \
  pstack \
  valgrind \
  tcpdump \
  cronolog \
  libvterm-dev \
  clang \
  protobuf-compiler \
  libgtest-dev \
  libgmock-dev \
  libbenchmark-dev \
  libgrpc-dev \
  libgrpc++-dev \
  protobuf-compiler-grpc

# Emacs (full GUI + terminal build via snap)
snap install emacs --classic

# Claude Code CLI
curl -fsSL https://claude.ai/install.sh | bash

# oprofile: legacy kernel profiler; may be absent from Ubuntu 24.04 universe.
# The modern alternative is 'perf' via linux-tools-generic.
apt-get -y install oprofile \
  || { echo "WARNING: oprofile not available; installing linux-tools-generic for 'perf' instead."; \
       apt-get -y install linux-tools-generic; }

# dool: drop-in replacement for dstat (removed from Ubuntu 22.04+)
apt-get -y install dool \
  || echo "WARNING: dool not available; install manually via: pip3 install dstat"

# ---------------------------------------------------------------------------
# 8. Bazel build system
# ---------------------------------------------------------------------------
curl -fsSL https://bazel.build/bazel-release.pub.gpg \
  | gpg --dearmor -o /usr/share/keyrings/bazel-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] \
https://storage.googleapis.com/bazel-apt stable jdk1.8" \
  | tee /etc/apt/sources.list.d/bazel.list > /dev/null

apt-get update
apt-get -y install bazel

# ---------------------------------------------------------------------------
# 9. Kernel tuning for ThreadSanitizer (TSan) and GDB
#
# Kernel 6.1+ defaults vm.mmap_rnd_bits to 32, which exceeds TSan's supported
# range (max 30).  TSan aborts with "unexpected memory mapping" at startup
# unless this is reduced.  28 is the standard workaround.
#
# Ubuntu 24.04 defaults kernel.yama.ptrace_scope to 1, which prevents gdb
# from attaching to an already-running process.  Setting it to 0 allows any
# process to attach to another owned by the same user.
# ---------------------------------------------------------------------------
cat > /etc/sysctl.d/99-tsan.conf << 'EOF'
vm.mmap_rnd_bits=28
EOF
sysctl -p /etc/sysctl.d/99-tsan.conf

cat > /etc/sysctl.d/10-ptrace.conf << 'EOF'
kernel.yama.ptrace_scope = 0
EOF
sysctl -p /etc/sysctl.d/10-ptrace.conf

# ---------------------------------------------------------------------------
# 10. SIGAR — Hyperic SIGAR 1.6.4 (pre-built binaries)
#
# The hyperic-sigar project was archived around 2016 and is no longer
# maintained.  The pre-built x86_64 ELF shared library still loads on
# modern glibc-based Linux.  There is no pre-built arm64 binary.
# ---------------------------------------------------------------------------
cd /tmp
wget -O hyperic-sigar-1.6.4.zip \
  "https://sourceforge.net/projects/sigar/files/sigar/1.6/hyperic-sigar-1.6.4.zip/download"
unzip -q hyperic-sigar-1.6.4.zip
cp hyperic-sigar-1.6.4/sigar-bin/include/*.h /usr/local/include/

if [[ "$ARCH" -eq 32 ]]; then
  cp hyperic-sigar-1.6.4/sigar-bin/lib/libsigar-x86-linux.so /usr/local/lib/
elif [[ "$IS_ARM64" -eq 1 ]]; then
  echo "WARNING: No pre-built SIGAR binary for arm64. SIGAR will not be available."
else
  cp hyperic-sigar-1.6.4/sigar-bin/lib/libsigar-amd64-linux.so /usr/local/lib/
fi

rm -rf /tmp/hyperic-sigar-1.6.4 /tmp/hyperic-sigar-1.6.4.zip

# ---------------------------------------------------------------------------
# 11. Apache Hadoop 3.4.3 (replaces hadoop-0.20)
# ---------------------------------------------------------------------------
HADOOP_VERSION=3.4.3
cd /tmp
wget "https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
tar -xzf "hadoop-${HADOOP_VERSION}.tar.gz" -C /opt
ln -sfn "/opt/hadoop-${HADOOP_VERSION}" /opt/hadoop

cat > /etc/profile.d/hadoop.sh << 'EOF'
export HADOOP_HOME=/opt/hadoop
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
EOF

rm -f "/tmp/hadoop-${HADOOP_VERSION}.tar.gz"

# ---------------------------------------------------------------------------
# 12. SBT (Scala Build Tool) — required for building Scrooge
# ---------------------------------------------------------------------------
curl -fsSL \
  "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" \
  | gpg --dearmor -o /usr/share/keyrings/sbt-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/sbt-keyring.gpg] \
https://repo.scala-sbt.org/scalasbt/debian all main" \
  | tee /etc/apt/sources.list.d/sbt.list > /dev/null

apt-get update
apt-get -y install sbt

# ---------------------------------------------------------------------------
# 13. Scrooge — Twitter's Scala Thrift binding generator
#
# NOTE: Scrooge's build configuration may change over time.  If 'sbt assembly'
# fails, consult https://github.com/twitter/scrooge for the current build
# instructions.
# ---------------------------------------------------------------------------
cd /usr/src
git clone https://github.com/twitter/scrooge.git
cd scrooge
# Pin to 22.12.0: later releases depend on com.twitter:util-validator-constraints
# which was never published to Maven Central, causing the build to fail.
git checkout scrooge-22.12.0
# Discard duplicate Bazel BUILD files that Twitter ships inside dependency JARs
cat > scrooge-generator/merge-override.sbt << 'SCALA'
assembly / assemblyMergeStrategy := {
  case "BUILD" => MergeStrategy.discard
  case x => (assembly / assemblyMergeStrategy).value(x)
}
SCALA
sbt scrooge-generator/assembly

# ---------------------------------------------------------------------------
# 14. Docker — for containerized deployment
# ---------------------------------------------------------------------------
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get -y install \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# ---------------------------------------------------------------------------
# 15. Ruby gems (same set as original CentOS script)
# ---------------------------------------------------------------------------
gem install capistrano sinatra rack thin json titleize

# ---------------------------------------------------------------------------
# Final dynamic-linker cache refresh
# ---------------------------------------------------------------------------
ldconfig

# ---------------------------------------------------------------------------
# Recommended ~/.bashrc additions
# ---------------------------------------------------------------------------
if [[ "$IS_ARM64" -eq 1 ]]; then
  _java_home_display=/usr/lib/jvm/java-17-openjdk-arm64
else
  _java_home_display=/usr/lib/jvm/java-17-openjdk-amd64
fi

cat << EOF

================================================================================
Add the following to ~/.bashrc (these are already set for login shells via
/etc/profile.d/, but are needed for non-login interactive shells as well):
================================================================================

# Java 17
export JAVA_HOME=${_java_home_display}
export PATH=\$PATH:\$JAVA_HOME/bin

# Apache Hadoop
export HADOOP_HOME=/opt/hadoop
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin

# Docker — allow running docker without sudo (requires logout/login to take effect)
# Run once: sudo usermod -aG docker \$USER
# Then add to ~/.bashrc if you want a reminder check:
# groups | grep -q docker || echo "WARNING: not in docker group"

# Claude Code
export PATH=\$PATH:\$HOME/.local/bin

================================================================================
EOF
