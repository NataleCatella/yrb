#!/usr/bin/env bash
# Runs INSIDE a linux/amd64 ruby:4.0.2-slim container. Builds a prebuilt
# x86_64-linux-gnu y-rb gem matching prod's Ruby/glibc ABI exactly, so
# `bundle install` in the prod image never compiles Rust. The fork is mounted
# read-only at /src; we copy to /build so container (root) writes never touch
# the host tree, and drop the finished .gem in /out. CARGO_HOME and the target
# dir live on mounted caches so a re-run after a failure skips re-downloading /
# re-compiling the crate graph (QEMU amd64 emulation is slow).
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export CARGO_HOME=/cargo
export RUSTUP_HOME=/rustup
export CARGO_TARGET_DIR=/cargo-target
export PATH="$CARGO_HOME/bin:$PATH"

apt-get update -qq
# clang + libclang-dev: the yrs crate graph pulls bindgen, which needs
# libclang.so at build time (present on the host Mac via Xcode, absent in slim).
apt-get install -y --no-install-recommends build-essential git curl pkg-config ca-certificates clang libclang-dev >/dev/null

# Idempotent: with RUSTUP_HOME/CARGO_HOME on cache mounts, a re-run is instant
# and (unlike the command -v guard) guarantees a default toolchain is set even
# though /root and the container FS are fresh each run.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --no-modify-path --default-toolchain stable >/dev/null
echo "rustc: $(rustc --version)"

gem install --no-document rake rake-compiler rake-compiler-dock >/dev/null
gem install --no-document rb_sys -v '~> 0.9.110' >/dev/null

cp -a /src /build
rm -rf /build/ext/*/target /build/target /build/tmp /build/pkg /build/lib/yrb.bundle
cd /build

# bundler/gem_tasks (loaded by the Rakefile) needs exactly ONE *.gemspec to
# infer the gem name. Move the extra platform spec out while rake compiles.
mv y-rb-platform.gemspec /tmp/y-rb-platform.gemspec

ruby -v
rake compile
ls -l lib/yrb.so

mv /tmp/y-rb-platform.gemspec y-rb-platform.gemspec
GEM_PLATFORM=x86_64-linux-gnu gem build y-rb-platform.gemspec
cp -v y-rb-*-x86_64-linux-gnu.gem /out/
echo "LINUX-GEM-BUILD-OK"
