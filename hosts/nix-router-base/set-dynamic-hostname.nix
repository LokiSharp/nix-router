{
  lib,
  mylib,
  myvars,
  pkgs,
  ...
}:
{
  systemd.services.set-dynamic-hostname = {
    description = "Set hostname dynamically from QEMU fw_cfg";
    after = [ "sysinit.target" ];
    before = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeScript "set-hostname" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail # 脚本严格模式，遇到错误会立即退出

        # 检查 QEMU fw_cfg 文件是否存在
        if [ -f /sys/firmware/qemu_fw_cfg/by_name/opt/vm_hostname/raw ]; then
          hostname_from_fwcfg="$(cat /sys/firmware/qemu_fw_cfg/by_name/opt/vm_hostname/raw)"
          # 设置当前运行内核的主机名
          ${pkgs.coreutils}/bin/echo "$hostname_from_fwcfg" > /proc/sys/kernel/hostname
        else
          # 如果 fw_cfg 文件不存在，则打印警告信息到系统日志
          ${pkgs.systemd}/bin/systemd-cat -t set-dynamic-hostname-warning echo "Warning: QEMU fw_cfg hostname file not found. Hostname might not be dynamic."
        fi
      '';
    };
  };
}
