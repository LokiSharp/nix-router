# DNS 服务配置 - BIND9 权威DNS服务器
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
  services.bind = {
    enable = true;
    ipv4Only = false;

    # DNS转发配置
    forwarders = coreVars.dns.forwarders;
    forward = "only";

    # 监听配置
    listenOn = [ coreVars.dns.listen_ip ];
    listenOnIpv6 = [ ];

    # 本地域名区域配置
    zones = {
      "${coreVars.domain}" = {
        master = true;
        file = pkgs.writeText "${coreVars.domain}.zone" ''
          $TTL 86400
          @   IN  SOA ns1.${coreVars.domain}. admin.${coreVars.domain}. (
                  ${coreVars.dns.zone_serial}  ; Serial
                  3600        ; Refresh  
                  1800        ; Retry
                  604800      ; Expire
                  86400 )     ; Minimum TTL

          ; 域名服务器记录
          @           IN  NS  ns1.${coreVars.domain}.

          ; 核心服务器记录
          ns1         IN  A   ${coreVars.dns.listen_ip}
          gateway     IN  A   ${coreVars.dns.listen_ip}

          ; 子路由器记录
          ${lib.concatMapStringsSep "\n          " (
            router: "${lib.toLower (lib.replaceStrings [ "-" ] [ "" ] router.name)}    IN  A   ${router.ip}"
          ) coreVars.routers}
        '';
      };

      # 反向DNS区域 (10.0.0.x)
      "0.0.10.in-addr.arpa" = {
        master = true;
        file = pkgs.writeText "0.0.10.in-addr.arpa.zone" ''
          $TTL 86400
          @   IN  SOA ns1.${coreVars.domain}. admin.${coreVars.domain}. (
                  ${coreVars.dns.zone_serial}  ; Serial
                  3600        ; Refresh
                  1800        ; Retry  
                  604800      ; Expire
                  86400 )     ; Minimum TTL

          ; 域名服务器记录
          @       IN  NS  ns1.${coreVars.domain}.

          ; 反向解析记录
          1       IN  PTR gateway.${coreVars.domain}.
          ${lib.concatMapStringsSep "\n          " (
            router:
            let
              ipLast = lib.last (lib.splitString "." router.ip);
            in
            "${ipLast}      IN  PTR ${
              lib.toLower (lib.replaceStrings [ "-" ] [ "" ] router.name)
            }.${coreVars.domain}."
          ) coreVars.routers}
        '';
      };
    };

    # DNS服务器安全选项
    extraOptions = ''
      // 访问控制
      allow-query { ${coreVars.networks.lan.network}; 127.0.0.1; };
      allow-recursion { none; };
      recursion no;

      // 安全设置
      version "Professional DNS Server";
      hostname "ns1.${coreVars.domain}";
    '';
  };
}
