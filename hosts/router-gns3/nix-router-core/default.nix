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

  # Core Router 作为主要网关路由器的服务配置
  services = {
    # DNS 和 DHCP 服务 (使用 dnsmasq)
    dnsmasq = {
      enable = true;
      settings = {
        # 监听接口
        interface = "br-lan";
        bind-interfaces = true;

        # DNS 设置
        domain-needed = true;
        bogus-priv = true;
        no-resolv = true;

        # 上游 DNS 服务器
        server = [
          "8.8.8.8"
          "1.1.1.1"
          "114.114.114.114"
        ];

        # 本地域名解析
        local = "/router.local/";
        domain = "router.local";
        expand-hosts = true;

        # DHCP 配置
        dhcp-range = "192.168.100.10,192.168.100.100,255.255.255.0,12h";
        dhcp-option = [
          "option:router,192.168.100.1"
          "option:dns-server,192.168.100.1"
          "option:domain-name,router.local"
        ];

        # DHCP 授权配置
        dhcp-authoritative = true;
        dhcp-leasefile = "/var/lib/dnsmasq/dnsmasq.leases";
      };
    };

    # BIRD 路由守护进程 - 作为核心路由器
    bird = {
      enable = true;
      config = ''
        # 路由表定义
        ipv4 table master4;
        ipv6 table master6;

        # 内核协议 - 同步路由表到内核
        protocol kernel {
          ipv4 {
            import all;
            export all;
          };
        }

        # 设备协议 - 监控网络接口
        protocol device {
        }

        # 静态路由协议 - 默认网关
        protocol static {
          ipv4 {
            export all;
          };
          route 0.0.0.0/0 via 192.168.1.1; # 上游网关
        }

        # OSPF 协议 - 与其他路由器通信
        protocol ospf v2 ospf_core {
          ipv4 {
            import all;
            export all;
          };
          area 0 {
            interface "br-lan" {
              cost 1;  # 核心路由器成本最低
              type broadcast;
              hello 5;
              dead 20;
            };
          };
        }

        # RIP 协议备份
        protocol rip rip_backup {
          ipv4 {
            import all;
            export all;
          };
          interface "br-lan" {
            metric 2;
          };
        }
      '';
    };

    # NTP 时间同步服务（保留基本时间同步）
    chrony = {
      enable = true;
      servers = [ "pool.ntp.org" ];
    };

    # SSH 服务（网关管理）
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = lib.mkForce "yes";
        PasswordAuthentication = false;
      };
    };
  };

  # Core Router 的网络配置
  networking = {
    # 启用 IP 转发
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        53 # DNS
        67 # DHCP
        179 # BGP
      ];
      allowedUDPPorts = [
        53 # DNS
        67 # DHCP
        68 # DHCP
        520 # RIP
      ];
    };

    # NAT 配置 - 作为网关
    nat = {
      enable = true;
      internalInterfaces = [ "br-lan" ];
      externalInterface = "eth0"; # 假设 eth0 连接上游
    };

    # 静态IP配置
    interfaces.br-lan = {
      ipv4.addresses = [
        {
          address = "192.168.100.1";
          prefixLength = 24;
        }
      ];
    };
  };

  # Core Router 的软件包（仅保留核心工具）
  environment.systemPackages = with pkgs; [
    bird3
    dnsutils
    iproute2
  ];

  # Core Router 的内核参数（简化配置）
  boot.kernel.sysctl = {
    # IP 转发
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;

    # 基本安全设置
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
  };

  system.stateVersion = "24.11";
}
