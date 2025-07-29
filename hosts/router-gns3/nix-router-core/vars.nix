# Core 路由器变量配置
# 用于多冗余核心交换机部署的共享变量
{
  pkgs,
  lib,
  ...
}:
{
  # ===== 核心路由器变量 =====
  coreRouter = {
    # 核心路由器基础信息
    id = 1; # 核心路由器编号 (1=主, 2=备1, 3=备2...)
    hostname = "nix-router-core";
    domain = "router.lan";

    # 网络地址配置
    networks = {
      # 管理网络
      lan = {
        network = "10.0.0.0/24";
        gateway = "10.0.0.1";
        start = "10.0.0.50";
        end = "10.0.0.100";
      };

      # WAN 上游网络
      wan = {
        interface = "wan0";
        upstream_gateway = "192.168.1.1";
      };
    };

    # DNS 服务器配置
    dns = {
      forwarders = [
        "8.8.8.8" # Google DNS 主
        "8.8.4.4" # Google DNS 备
        "1.1.1.1" # Cloudflare DNS 主
        "1.0.0.1" # Cloudflare DNS 备
      ];
      listen_ip = "10.0.0.1";
      zone_serial = "2024071801";
    };

    # 子路由器静态分配
    routers = [
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

    # OSPF 路由协议配置
    ospf = {
      area = 0;
      hello_interval = 5;
      dead_interval = 20;
      cost = 1;
    };
  };
}
