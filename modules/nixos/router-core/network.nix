{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.routerCore.router;
in
{
  options.routerCore.router = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable this machine to act as a network router.";
    };

    lan = lib.mkOption {
      type = lib.types.submodule {
        options = {
          interface = lib.mkOption {
            type = lib.types.str;
            default = "br-lan";
            description = "The name of the LAN (internal) network interface.";
          };
          ip = lib.mkOption {
            type = lib.types.str;
            description = "The static IP address of the LAN interface.";
            # 示例: "192.168.1.1"
          };
          prefixLength = lib.mkOption {
            type = lib.types.int;
            default = 24;
            description = "The prefix length for the LAN subnet.";
          };
        };
      };
      description = "LAN (internal network) configuration.";
    };

    wan = lib.mkOption {
      type = lib.types.submodule {
        options = {
          interface = lib.mkOption {
            type = lib.types.str;
            description = "The name of the WAN (external) network interface.";
            # 示例: "eth0" or "eno1"
          };
        };
      };
      description = "WAN (external network) configuration.";
    };

    nat.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable NAT (masquerading) for the LAN.";
    };

    firewall = lib.mkOption {
      type = lib.types.submodule {
        options = {
          openTCPPorts = lib.mkOption {
            type = lib.types.listOf lib.types.port;
            default = [ ];
            description = "List of additional TCP ports to open on the firewall.";
          };
          openUDPPorts = lib.mkOption {
            type = lib.types.listOf lib.types.port;
            default = [ ];
            description = "List of additional UDP ports to open on the firewall.";
          };
        };
      };
      default = { };
      description = "Firewall configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    # 当 mySystem.router.enable = true 时，以下所有配置都会被应用

    # ----- 核心路由功能 -----
    # 自动启用内核的 IP 转发功能
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;

      # 应用推荐的网络安全加固设置
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
    };

    # ----- 网络服务配置 -----
    networking = {
      # 防火墙配置
      firewall = {
        enable = true;
        # 默认开放 SSH 和 DNS，并合并用户自定义的端口
        allowedTCPPorts = [
          22
          53
        ] ++ cfg.firewall.openTCPPorts;
        allowedUDPPorts = [
          53
          67
          68
        ] ++ cfg.firewall.openUDPPorts;
      };

      # NAT 网关配置
      # 仅在 nat.enable 为 true 时启用
      nat = lib.mkIf cfg.nat.enable {
        enable = true;
        internalInterfaces = [ cfg.lan.interface ];
        externalInterface = cfg.wan.interface;
      };

      # 静态 IP 地址配置 (动态设置接口名称)
      interfaces.${cfg.lan.interface} = {
        ipv4.addresses = [
          {
            address = cfg.lan.ip;
            prefixLength = cfg.lan.prefixLength;
          }
        ];
      };
    };
  };
}
