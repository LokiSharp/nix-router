# Nix-Router-Core 的特定配置 - 主要网关路由器
# 模块化配置，支持多冗余核心交换机部署
{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    # 基础配置模块
    ./../../nix-router-base/disk.nix
    ./../../nix-router-base/networking.nix
    ./../../nix-router-base/set-dynamic-hostname.nix
  ];

  routerCore.router = {
    enable = true; # 启用路由器功能

    # 配置内外网接口和地址
    lan = {
      interface = "br-lan";
      ip = "10.0.0.3";
      prefixLength = 24;
    };
    wan = {
      interface = "wan0"; # 这是你的外网网卡名
    };
  };

  routerCore.dhcp = {
    enable = true;
    interface = "br-lan";
    domain = "router.lan"; # 自定义你的局域网域名

    pool = {
      start = "10.0.0.150";
      end = "10.0.0.200";
      gateway = "10.0.0.1"; # 通常这是你路由器的 LAN IP
    };

    dnsServers = [
      "8.8.8.8" # Google DNS 主
      "8.8.4.4" # Google DNS 备
      "1.1.1.1" # Cloudflare DNS 主
      "1.0.0.1" # Cloudflare DNS 备
    ];

    # 声明所有需要静态分配IP的主机
    staticHosts = [
      {
        name = "Nix-Router-1";
        ip = "10.0.0.11";
      }
      {
        name = "Nix-Router-2";
        ip = "10.0.0.12";
      }
      {
        name = "Nix-Router-3";
        ip = "10.0.0.13";
      }
      {
        name = "Nix-Router-4";
        ip = "10.0.0.14";
      }
      {
        name = "Nix-Router-5";
        ip = "10.0.0.15";
      }
    ];
  };

  routerCore.routing = {
    enable = true;

    # 设置默认路由的上游网关
    defaultGateway = "192.168.1.1"; # 你的 ISP 提供的网关地址

    # 配置 OSPF
    ospf = {
      enable = true;
      area = "0.0.0.0";
      interfaces = {
        # 在 br-lan 接口上运行 OSPF
        "br-lan" = {
          cost = 100; # 备用路由器成本高
          helloInterval = 10;
          deadInterval = 40;
        };
        # 如果有其他内部接口，也可以在这里添加
        # "br-iot" = {
        #   cost = 20;
        # };
      };
    };
  };

  routerCore.ha = {
    enable = true;
    role = "BACKUP"; # <--- 关键：将这台机器声明为备用节点
    interface = "br-lan";
    virtualRouterId = 51;
    virtualIp = "10.0.0.1"; # 这是客户端使用的虚拟网关 IP
  };

  routerCore.dns = {
    enable = true;
    domain = "router.lan";
    listenAddress = "10.0.0.1";
    zoneSerial = "2024071801";
  };

  # ===== 系统软件包 =====
  environment.systemPackages = with pkgs; [
    bird3 # 路由守护进程
    bind # DNS服务器
    dnsmasq # DHCP服务器
    iproute2 # 网络管理工具
  ];

  system.stateVersion = "24.11";
}
