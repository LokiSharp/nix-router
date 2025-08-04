{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.routerCore.ha;
in
{
  options.routerCore.ha = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable High Availability (HA) using Keepalived (VRRP).";
    };

    role = lib.mkOption {
      type = lib.types.enum [
        "PRIMARY"
        "BACKUP"
      ];
      description = "The role of this node in the HA cluster (PRIMARY or BACKUP).";
      # 示例: "PRIMARY"
    };

    interface = lib.mkOption {
      type = lib.types.str;
      description = "The network interface to run VRRP on.";
      # 示例: "br-lan"
    };

    virtualRouterId = lib.mkOption {
      type = lib.types.int;
      default = 51;
      description = "The Virtual Router ID. Must be the same for all nodes in the cluster.";
    };

    virtualIp = lib.mkOption {
      type = lib.types.str;
      description = "The Virtual IP (VIP) address that clients will use as their gateway.";
      # 示例: "192.168.10.1"
    };
  };

  config = lib.mkIf cfg.enable {
    # 确保 keepalived 软件包已安装
    environment.systemPackages = [ pkgs.keepalived ];

    # Keepalived 服务配置
    services.keepalived = {
      enable = true;

      # VRRP 实例配置
      vrrpInstances = {
        # 我们使用一个固定的实例名 "VRRP_HA"
        "VRRP_HA" = {
          # 监控的接口，从我们的选项中获取
          interface = cfg.interface;

          # 虚拟路由器 ID
          virtualRouterId = cfg.virtualRouterId;

          # 核心逻辑：根据角色自动设置优先级
          # 主路由器优先级高 (200)，备用路由器优先级低 (100)
          priority = if cfg.role == "PRIMARY" then 200 else 100;

          # 定义虚拟 IP 地址 (VIP)
          virtualIps = [
            {
              addr = cfg.virtualIp;
            }
          ];

          # (可选) 你可以在这里添加更多高级的 keepalived 设置
          # 例如: advert_int, authentication, etc.
        };
      };
    };
  };
}
