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

    # 核心路由器功能模块
    ./dns.nix # DNS 服务配置
    ./dhcp.nix # DHCP 服务配置
    ./routing.nix # 路由协议配置
    ./network.nix # 网络和防火墙配置
  ];

  # ===== 系统软件包 =====
  environment.systemPackages = with pkgs; [
    bird3 # 路由守护进程
    bind # DNS服务器
    dnsmasq # DHCP服务器
    iproute2 # 网络管理工具
  ];

  system.stateVersion = "24.11";
}
