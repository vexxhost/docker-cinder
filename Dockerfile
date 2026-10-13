# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:2025.2@sha256:5fbd2a6bbb802f86ce88d2f6cae32506c0d7660330c7c5402804475063098732 AS build
ARG CINDER_VERSION=27.0.0+a8e.25.9
RUN <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        "cinder==${CINDER_VERSION}" \
        py-pure-client \
        python-3parclient \
        storpool \
        storpool.spopenstack
EOF
ADD --chmod=644 \
    https://github.com/storpool/storpool-openstack-integration/raw/master/drivers/cinder/openstack/caracal/storpool.py \
    /var/lib/openstack/lib/python3.12/site-packages/cinder/volume/drivers/storpool.py
ADD --chmod=644 \
    https://github.com/storpool/storpool-openstack-integration/raw/master/drivers/os_brick/openstack/caracal/storpool.py \
    /var/lib/openstack/lib/python3.12/site-packages/os_brick/initiator/connectors/storpool.py

FROM ghcr.io/vexxhost/python-base:2025.2@sha256:6fb56d04cd98fac078a475f0e1135ed25afc88493d9b04fcaa4a4e35dbd59cb5
RUN \
    groupadd -g 42424 cinder && \
    useradd -u 42424 -g 42424 -M -d /var/lib/cinder -s /usr/sbin/nologin -c "Cinder User" cinder && \
    mkdir -p /etc/cinder /var/log/cinder /var/lib/cinder /var/cache/cinder && \
    chown -Rv cinder:cinder /etc/cinder /var/log/cinder /var/lib/cinder /var/cache/cinder
RUN <<EOF bash -xe
apt-get update -qq
apt-get install -qq -y --no-install-recommends \
    ceph-common dmidecode lsscsi nfs-common nvme-cli python3-rados python3-rbd qemu-utils qemu-block-extra sysfsutils udev util-linux
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
ADD --chmod=755 https://dl.k8s.io/release/v1.34.1/bin/linux/amd64/kubectl /usr/local/bin/kubectl
COPY --from=build --link /var/lib/openstack /var/lib/openstack
