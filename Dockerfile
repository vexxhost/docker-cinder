# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:2023.1@sha256:fbfe0eec83d7dec98cdf01964bf683f891a4c3fd698148d3d7e0c416d047f2de AS build
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

FROM ghcr.io/vexxhost/python-base:2023.1@sha256:ca30d298502521fcf6f8e703c4686de61f3e1341b8b5c1312b8696757861a5e8
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
