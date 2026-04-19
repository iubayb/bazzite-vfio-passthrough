#!/bin/bash
# Bootstrap installer — installs Debian packages + copies config files.
# Does NOT modify GRUB cmdline, install kernels, or define libvirt domains.
# Read README.md before running.

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Run as root (sudo $0)" >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Installing from: $REPO_DIR"

if command -v apt-get >/dev/null 2>&1; then
    echo "==> Installing Debian/Ubuntu packages"
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        qemu-system-x86 qemu-system-modules-spice qemu-utils \
        libvirt-daemon-system libvirt-clients virt-manager virt-viewer \
        ovmf swtpm swtpm-tools bridge-utils dnsmasq-base \
        gir1.2-spiceclientgtk-3.0 gir1.2-spiceclientglib-2.0 spice-client-gtk
else
    echo "Not apt-based — install qemu, libvirt, virt-manager, virt-viewer, OVMF, swtpm, and SPICE GTK client (gir1.2-spiceclientgtk-3.0 equivalent) manually."
fi

echo "==> Copying config files"
install -m 0755 -o root -g root "$REPO_DIR/etc/libvirt/hooks/qemu"            /etc/libvirt/hooks/qemu
install -m 0644 -o root -g root "$REPO_DIR/etc/X11/xorg.conf.d/20-igpu-only.conf" /etc/X11/xorg.conf.d/20-igpu-only.conf
install -m 0644 -o root -g root "$REPO_DIR/etc/modprobe.d/vfio.conf"          /etc/modprobe.d/vfio.conf
install -m 0755 -o root -g root "$REPO_DIR/usr/local/sbin/gaming-vm-verify"   /usr/local/sbin/gaming-vm-verify
install -m 0755 -o root -g root "$REPO_DIR/usr/local/sbin/vfio-gpu-reclaim"   /usr/local/sbin/vfio-gpu-reclaim
install -m 0755 -o root -g root "$REPO_DIR/usr/local/sbin/vm-shutdown-safe"   /usr/local/sbin/vm-shutdown-safe
install -m 0755 -o root -g root "$REPO_DIR/usr/local/sbin/dualsense-vm-hotplug" /usr/local/sbin/dualsense-vm-hotplug
install -m 0644 -o root -g root "$REPO_DIR/etc/udev/rules.d/99-dualsense-vm-hotplug.rules" /etc/udev/rules.d/99-dualsense-vm-hotplug.rules
udevadm control --reload-rules

echo
echo "==> Files installed. Next:"
echo "  1. Adjust examples/bazzite.xml for your hardware, then: virsh define examples/bazzite.xml"
echo "  2. Reboot, then: sudo /usr/local/sbin/gaming-vm-verify"
echo "  3. Optional safe stop helper: sudo /usr/local/sbin/vm-shutdown-safe bazzite 150"
