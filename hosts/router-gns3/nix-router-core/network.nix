# 网络配置 - 防火墙、NAT、接口配置
{
  pkgs,
  lib,
  config,
  ...
}:
let
  vars = import ./vars.nix { inherit pkgs lib; };
  coreVars = vars.coreRouter;
in
{
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
      externalInterface = coreVars.networks.wan.interface; # 外网接口
    };

    # 静态IP地址配置
    interfaces.br-lan = {
      ipv4.addresses = [
        {
          address = coreVars.networks.lan.gateway;
          prefixLength = 24;
        }
      ];
    };
  };

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
}
