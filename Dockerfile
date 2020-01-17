FROM ubuntu:18.04 AS cdt-patched

# command-line arguments
ARG nproc=2

# other variables
ARG cdt_linker_patch=single-thread-fix.patch

WORKDIR /
ADD  $cdt_linker_patch /${cdt_linker_patch}
RUN \
  echo ">>> Installing dependencies ..." && \
  apt-get update && \
  apt-get -V -y --no-install-recommends --no-install-suggests install apt-utils ca-certificates && \
  echo ">>> Some more dependencies (because eosio.cdt/build.sh doesn't support noninteractive mode) ..." && \
  apt-get -V -y --no-install-recommends --no-install-suggests install \
    git \
    \
    clang-4.0 lldb-4.0 libclang-4.0-dev cmake make automake libbz2-dev libssl-dev \
    libgmp3-dev autotools-dev build-essential libicu-dev python2.7-dev python3-dev \
    autoconf libtool curl zlib1g-dev doxygen graphviz && \
  \
  echo ">>> Cloning git repository ... " && \
  echo ">>> INFO:" && \
  echo " * tarball https://github.com/EOSIO/eosio.cdt/archive/v1.6.3.tar.gz doesn't contain" && \
  echo "   submodule sources (e.g. eosio_llvm), so may not be used for building CDT" && \
  echo " * shallow copying allows to reduce the amount of cloned data" && \
  git clone --recurse-submodules -b v1.6.3 --shallow-since=2019-01-01 https://github.com/EOSIO/eosio.cdt.git && \
  \
  cd eosio.cdt/ && \
  \
  echo ">>> Applying patch for single-thread compiling ..." && \
  patch -p1 -d eosio_llvm/tools/lld/ -i /${cdt_linker_patch} && \
  \
  echo ">>> Compiling ..." && \
  env CORES=${nproc} ./build.sh && \
  \
  echo ">>> Installing ..." && \
  ./install.sh && \
  \
  echo ">>> Cleaning ..." && \
  cd / && rm -rf eosio.cdt ${cdt_threads_patch} ${cdt_linker_patch}

USER root
WORKDIR /app
