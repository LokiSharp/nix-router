# modules/network/firewall.nix
{ config, lib, ... }:

let
  managementInterface = "mgnt0";
  wanInterface = "wan0";
  lanBridge = "br-lan";
in
{
  networking.nftables = {
    enable = true;
    ruleset = ''
      # =========================================================================
      # 过滤器表 (Filter Table) - 用于包过滤和安全策略
      # =========================================================================
      table inet filter { # inet 表同时适用于 IPv4 和 IPv6
        # ---------------------------------------------------------------------
        # 入站链 (Input Chain) - 抵达路由器自身接口的流量
        # 默认：阻止所有传入连接流量，除了明确允许的。
        # ---------------------------------------------------------------------
        chain input {
          type filter hook input priority 0;

          # 接受所有来自本地回环接口的流量 (lo)
          iifname lo accept
          iifname dummy0 accept # 考虑如果不需要可以移除

          # 接受由路由器发起并已建立/相关的连接的返回流量 (有状态防火墙的关键)
          ct state { established, related } accept

          # 允许必要的 ICMP/ICMPv6 错误和控制消息
          # 这些对于路由器的正常功能（如路径MTU发现、邻居发现）至关重要。
          # 路由器的 ICMP 类型应该比普通主机更全面。
          ip6 nexthdr icmpv6 icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert, nd-router-solicit } accept
          ip protocol icmp icmp type { destination-unreachable, router-advertisement, time-exceeded, parameter-problem, echo-request } accept

          # ---------------------------------------------------------------------
          # 接口特定规则
          # ---------------------------------------------------------------------

          # 允许管理接口 (${managementInterface}) 的 SSH (端口 22)
          iifname ${managementInterface} tcp dport 22 accept

          # 允许 WAN 接口 (${wanInterface}) 的 BGP (端口 179)
          iifname ${wanInterface} tcp dport 179 accept

          # 允许 LAN 接口 (${lanBridge}) 的所有传入流量
          iifname ${lanBridge} accept

          # 允许 LAN 侧的 DHCP (UDP 67, 68) 和 DNS (UDP 53, TCP 53) 请求到路由器
          iifname ${lanBridge} udp dport { 67, 68 } accept # DHCP 服务器
          iifname ${lanBridge} udp dport 53 accept         # DNS 服务器 (UDP)
          iifname ${lanBridge} tcp dport 53 accept         # DNS 服务器 (TCP)

          # ---------------------------------------------------------------------
          # 默认策略：计数并丢弃所有其他未明确允许的入站流量
          # ---------------------------------------------------------------------
          counter drop
        }


        # ---------------------------------------------------------------------
        # 出站链 (Output Chain) - 路由器自身发出的流量
        # 默认：允许所有路由器自身发出的流量。
        # ---------------------------------------------------------------------
        chain output {
          type filter hook output priority 0;
          accept
        }


        # ---------------------------------------------------------------------
        # 转发链 (Forward Chain) - 穿过路由器的流量 (从一个接口到另一个接口)
        # 默认：允许所有流量转发。
        # 如果需要更细粒度的控制，可以在这里添加规则。
        # ---------------------------------------------------------------------
        chain forward {
          type filter hook forward priority 0;
          accept
        }

      }

      # =========================================================================
      # NAT 表 (NAT Table) - 用于网络地址转换
      # =========================================================================
      table ip nat { # ip 表只适用于 IPv4
        # ---------------------------------------------------------------------
        # 后路由链 (Postrouting Chain) - 流量离开路由器前
        # 实现源地址转换 (SNAT/Masquerade)，让 LAN 侧设备访问外网。
        # ---------------------------------------------------------------------
        chain postrouting {
          type nat hook postrouting priority 100;
          oifname "${wanInterface}" masquerade;
        }
      }
    '';
  };
}
