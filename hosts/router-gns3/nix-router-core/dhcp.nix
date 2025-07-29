# DHCP 服务配置 - dnsmasq轻量级DHCP服务器
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
  services.dnsmasq = {
    enable = true;
    settings = {
      # 接口配置
      interface = "br-lan";
      bind-interfaces = true;

      # DHCP地址池配置
      dhcp-range = [ "${coreVars.networks.lan.start},${coreVars.networks.lan.end},12h" ];
      dhcp-authoritative = true;

      # 网络选项配置
      dhcp-option = [
        "option:router,${coreVars.networks.lan.gateway}" # 默认网关
        "option:dns-server,${coreVars.dns.listen_ip}" # DNS服务器
        "option:domain-name,${coreVars.domain}" # 域名后缀
      ];

      # 静态IP分配 (基于主机名)
      dhcp-host = map (router: "${router.name},${router.ip}") coreVars.routers;

      # 服务配置
      port = 0; # 禁用DNS(使用BIND)
      log-dhcp = true; # 启用DHCP日志
      log-facility = "/var/log/dnsmasq.log";

      # 域名配置
      local = "/${coreVars.domain}/";
      domain = coreVars.domain;
      expand-hosts = true;
    };
  };
}
