# Nix-Router-Core 的特定配置 - 主要网关路由器
{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./../../nix-router-base/disk.nix
    ./../../nix-router-base/networking.nix
    ./../../nix-router-base/set-dynamic-hostname.nix
  ];

  # ===== 网络服务配置 =====
  services = {
    # DNS 服务 - BIND9 权威DNS服务器
    bind = {
      enable = true;
      ipv4Only = false;

      # DNS转发配置
      forwarders = [
        "8.8.8.8" # Google DNS 主
        "8.8.4.4" # Google DNS 备
        "1.1.1.1" # Cloudflare DNS 主
        "1.0.0.1" # Cloudflare DNS 备
      ];
      forward = "only";

      # 监听配置
      listenOn = [ "10.0.0.1" ];
      listenOnIpv6 = [ ];

      # 本地域名区域配置
      zones = {
        "router.lan" = {
          master = true;
          file = pkgs.writeText "router.lan.zone" ''
            $TTL 86400
            @   IN  SOA ns1.router.lan. admin.router.lan. (
                    2024071801  ; Serial
                    3600        ; Refresh  
                    1800        ; Retry
                    604800      ; Expire
                    86400 )     ; Minimum TTL

            ; 域名服务器记录
            @           IN  NS  ns1.router.lan.

            ; 核心服务器记录
            ns1         IN  A   10.0.0.1
            gateway     IN  A   10.0.0.1

            ; 子路由器记录
            nix-router-1    IN  A   10.0.0.11
            nix-router-2    IN  A   10.0.0.12
            nix-router-3    IN  A   10.0.0.13
            nix-router-4    IN  A   10.0.0.14
            nix-router-5    IN  A   10.0.0.15
          '';
        };

        # 反向DNS区域 (10.0.0.x)
        "0.0.10.in-addr.arpa" = {
          master = true;
          file = pkgs.writeText "0.0.10.in-addr.arpa.zone" ''
            $TTL 86400
            @   IN  SOA ns1.router.lan. admin.router.lan. (
                    2024071801  ; Serial
                    3600        ; Refresh
                    1800        ; Retry  
                    604800      ; Expire
                    86400 )     ; Minimum TTL

            ; 域名服务器记录
            @       IN  NS  ns1.router.lan.

            ; 反向解析记录
            1       IN  PTR gateway.router.lan.
            11      IN  PTR nix-router-1.router.lan.
            12      IN  PTR nix-router-2.router.lan.
            13      IN  PTR nix-router-3.router.lan.
            14      IN  PTR nix-router-4.router.lan.
            15      IN  PTR nix-router-5.router.lan.
          '';
        };
      };

      # DNS服务器安全选项
      extraOptions = ''
        // 访问控制
        allow-query { 10.0.0.0/24; 127.0.0.1; };
        allow-recursion { none; };
        recursion no;

        // 安全设置
        version "Professional DNS Server";
        hostname "ns1.router.lan";
      '';
    };

    # DHCP 服务 - dnsmasq轻量级DHCP服务器
    dnsmasq = {
      enable = true;
      settings = {
        # 接口配置
        interface = "br-lan";
        bind-interfaces = true;

        # DHCP地址池配置
        dhcp-range = [ "10.0.0.50,10.0.0.100,12h" ];
        dhcp-authoritative = true;

        # 网络选项配置
        dhcp-option = [
          "option:router,10.0.0.1" # 默认网关
          "option:dns-server,10.0.0.1" # DNS服务器
          "option:domain-name,router.lan" # 域名后缀
        ];

        # 静态IP分配 (基于主机名)
        dhcp-host = [
          "Nix-Router-1,10.0.0.11"
          "Nix-Router-2,10.0.0.12"
          "Nix-Router-3,10.0.0.13"
          "Nix-Router-4,10.0.0.14"
          "Nix-Router-5,10.0.0.15"
        ];

        # 服务配置
        port = 0; # 禁用DNS(使用BIND)
        log-dhcp = true; # 启用DHCP日志
        log-facility = "/var/log/dnsmasq.log";

        # 域名配置
        local = "/router.lan/";
        domain = "router.lan";
        expand-hosts = true;
      };
    };

    # 路由服务 - BIRD路由守护进程
    bird = {
      enable = true;
      config = ''
        # 路由表定义
        ipv4 table master4;
        ipv6 table master6;

        # 内核路由协议 - 同步系统路由表
        protocol kernel {
          ipv4 {
            import all;
            export all;
          };
        }

        # 设备协议 - 监控网络接口状态
        protocol device {
        }

        # 静态路由协议 - 默认路由配置
        protocol static {
          ipv4 {
            export all;
          };
          # 上游默认路由
          route 0.0.0.0/0 via 192.168.1.1;
        }

        # OSPF协议 - 动态路由协议
        protocol ospf v2 ospf_core {
          ipv4 {
            import all;
            export all;
          };
          area 0 {
            interface "br-lan" {
              cost 1;           # 最低成本，优先选择
              type broadcast;   # 广播网络类型
              hello 5;          # Hello间隔5秒
              dead 20;          # 死亡检测20秒
            };
          };
        }
      '';
    };
  };

  # ===== 网络配置 =====
  networking = {
    # 防火墙配置
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH管理
        53 # DNS服务
      ];
      allowedUDPPorts = [
        53 # DNS查询
        67 # DHCP服务器
        68 # DHCP客户端
        89 # OSPF协议
      ];
    };

    # NAT网关配置
    nat = {
      enable = true;
      internalInterfaces = [ "br-lan" ]; # 内网接口
      externalInterface = "wan0"; # 外网接口
    };

    # 静态IP地址配置
    interfaces.br-lan = {
      ipv4.addresses = [
        {
          address = "10.0.0.1";
          prefixLength = 24;
        }
      ];
    };
  };

  # ===== 系统软件包 =====
  environment.systemPackages = with pkgs; [
    bird3 # 路由守护进程
    bind # DNS服务器
    dnsmasq # DHCP服务器
    iproute2 # 网络管理工具
  ];

  # ===== 内核参数优化 =====
  boot.kernel.sysctl = {
    # IP转发功能
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;

    # 网络安全设置
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
  };

  system.stateVersion = "24.11";
}
