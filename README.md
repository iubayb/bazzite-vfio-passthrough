# bazzite-vfio-passthrough

Dynamic AMD GPU passthrough for a `bazzite` KVM/libvirt VM, with the host running on iGPU (or a second GPU). The hook binds the dGPU to `vfio-pci` for VM runtime, then reclaims it back to host drivers when the VM stops.

Tested hardware: MSI Z490 Gaming Carbon WiFi, i9-10850K (UHD 630), Radeon RX 6800 XT, Debian trixie.

## What this setup provides

- Dynamic `amdgpu <-> vfio-pci` switching for one passed-through GPU.
- No automatic host reboot in the current hook flow.
- Deferred reclaim worker (`/usr/local/sbin/vfio-gpu-reclaim`) after VM stop.
- Safe VM shutdown helper (`/usr/local/sbin/vm-shutdown-safe`).

## Requirements

- IOMMU enabled (`intel_iommu=on` or `amd_iommu=on`).
- UEFI boot (CSM off).
- Host display on iGPU (or second dedicated host GPU).
- Kernel 6.17+ recommended for better AMD reset behavior.
- QEMU/libvirt/OVMF/virt-manager stack installed (handled by `install.sh` on apt-based systems).

## Install

```sh
git clone https://github.com/iubayb/bazzite-vfio-passthrough.git
cd bazzite-vfio-passthrough
sudo ./install.sh
```

Then customize:

1. `/etc/libvirt/hooks/qemu`: set `GPU_FUNCS` to your GPU function addresses.
2. `examples/bazzite.xml`: set disk source, CPU pinning, and PCI hostdev addresses.
3. Define VM: `virsh define examples/bazzite.xml`.
4. Reboot once, then run: `sudo /usr/local/sbin/gaming-vm-verify`.

## Daily workflow

- Start VM from virt-manager: hook unbinds host drivers and binds `vfio-pci`.
- Stop VM: hook schedules deferred reclaim via `/usr/local/sbin/vfio-gpu-reclaim`.
- For reliable guest shutdown, use:
  `sudo /usr/local/sbin/vm-shutdown-safe bazzite 150`
- Check hook and reclaim logs in `/var/log/libvirt-hooks.log`.

If reclaim fails on your hardware, reboot the host and inspect logs before retrying.

## DualSense notes

- Keep the VM USB controller (`qemu-xhci`) enabled.
- Wired DualSense passthrough (`054c:0ce6`) is included in `examples/bazzite.xml` with `startupPolicy='optional'`.
- Bluetooth adapter passthrough is optional (example AX201 `8087:0026` hostdev in XML).
- While BT adapter passthrough is active, host Bluetooth is unavailable.
- The hook now enforces BT adapter handoff (unbinds host `btusb` on VM start, rebinds on VM stop) to avoid shared-host ownership races.
- Controller speaker over Bluetooth is generally not available in this VM path; treat wired USB as the reliable route for full features.

The repo includes USB replug recovery for wired DualSense via `usr/local/sbin/dualsense-vm-hotplug` and `etc/udev/rules.d/99-dualsense-vm-hotplug.rules`.

## Key paths

- `etc/libvirt/hooks/qemu`
- `usr/local/sbin/vfio-gpu-reclaim`
- `usr/local/sbin/vm-shutdown-safe`
- `usr/local/sbin/gaming-vm-verify`
- `examples/bazzite.xml`
- `etc/udev/rules.d/99-dualsense-vm-hotplug.rules`

## Caveats

- Single-GPU hosts without iGPU/second host GPU are out of scope for this repo.
- Host and guest cannot use the same passed-through GPU at the same time.
- Dynamic reclaim reliability is hardware- and firmware-dependent.

## License

MIT
