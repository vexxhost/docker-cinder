# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:2024.1@sha256:2f047528a9d4ee55aa4232fec3c61ccd980c27f3e58693cc2b5968e365ba6f26 AS build
RUN --mount=type=bind,from=cinder,source=/,target=/src/cinder,readwrite <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        /src/cinder \
        purestorage \
        python-3parclient \
        storpool \
        storpool.spopenstack
EOF
ADD --chmod=644 \
    https://github.com/storpool/storpool-openstack-integration/raw/master/drivers/cinder/openstack/caracal/storpool.py \
    /var/lib/openstack/lib/python3.10/site-packages/cinder/volume/drivers/storpool.py
ADD --chmod=644 \
    https://github.com/storpool/storpool-openstack-integration/raw/master/drivers/os_brick/openstack/caracal/storpool.py \
    /var/lib/openstack/lib/python3.10/site-packages/os_brick/initiator/connectors/storpool.py

FROM ghcr.io/vexxhost/python-base:2024.1@sha256:4f0af45fa6e77ed4bdaeab14042b0760a90753478a79ddaff6fc88e1eeb4cdfc
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
ADD --chmod=755 https://dl.k8s.io/release/v1.29.3/bin/linux/amd64/kubectl /usr/local/bin/kubectl
COPY --from=build --link /var/lib/openstack /var/lib/openstack
