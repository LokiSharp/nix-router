{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  config = {
    boot = {
      loader = {
        timeout = 0;
      };

      initrd = {
        compressor = "zstd";
        compressorArgs = [
          "-19"
          "-T0"
        ];
        systemd.enable = true;
        postDeviceCommands = lib.mkIf (!config.boot.initrd.systemd.enable) ''
          # Set the system time from the hardware clock to work around a
          # bug in qemu-kvm > 1.5.2 (where the VM clock is initialised
          # to the *boot time* of the host).
          hwclock -s
        '';

        availableKernelModules = [
          "virtio_net"
          "virtio_pci"
          "virtio_mmio"
          "virtio_blk"
          "virtio_scsi"
        ];
        kernelModules = [
          "virtio_balloon"
          "virtio_console"
          "virtio_rng"
        ];
      };
    };
  };
}
