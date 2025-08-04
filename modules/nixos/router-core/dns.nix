{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.routerCore.dns;

  # ===== 辅助函数，用于生成区域文件内容 =====

  # 生成正向区域 (Forward Zone)
  generateForwardZone = ''
    $TTL 86400
    @   IN  SOA ns1.${cfg.domain}. admin.${cfg.domain}. (
            ${cfg.zoneSerial}  ; Serial
            3600        ; Refresh
            1800        ; Retry
            604800      ; Expire
            86400 )     ; Minimum TTL

    ; Name Server Records
    @           IN  NS  ns1.${cfg.domain}.

    ; A Records
    ns1         IN  A   ${cfg.listenAddress}
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: ip: "${lib.fixedWidthString 12 name}IN  A   ${ip}") cfg.records
    )}
  '';

  # 生成反向区域 (Reverse Zone)
  generateReverseZone =
    let
      # 从 IP "192.168.10.1" 中提取最后一部分 "1"
      getIpLastOctet = ip: lib.last (lib.splitString "." ip);
    in
    ''
      $TTL 86400
      @   IN  SOA ns1.${cfg.domain}. admin.${cfg.domain}. (
              ${cfg.zoneSerial}  ; Serial
              3600        ; Refresh
              1800        ; Retry
              604800      ; Expire
              86400 )     ; Minimum TTL

      ; Name Server Records
      @       IN  NS  ns1.${cfg.domain}.

      ; PTR Records
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: ip: "${lib.fixedWidthString 8 (getIpLastOctet ip)}IN  PTR ${name}.${cfg.domain}."
        ) cfg.records
      )}
    '';

  # 自动计算反向区域的名称, 例如从 "192.168.10.1" -> "10.168.192.in-addr.arpa"
  reverseZoneName =
    let
      octets = lib.splitString "." cfg.listenAddress;
      reversedOctets = lib.reverseList (lib.take 3 octets);
    in
    "${lib.concatStringsSep "." reversedOctets}.in-addr.arpa";

in
{
  options.routerCore.dns = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the BIND authoritative DNS server.";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      description = "The local domain name to serve (e.g., 'nix.lan').";
    };
    listenAddress = lib.mkOption {
      type = lib.types.str;
      description = "The primary IPv4 address for BIND to listen on.";
    };
    forwarders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "8.8.8.8"
        "1.1.1.1"
      ];
      description = "List of upstream DNS servers to forward queries to.";
    };
    allowQueryFrom = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "127.0.0.1" ];
      description = "List of networks (CIDR) or IPs allowed to query the server.";
    };
    zoneSerial = lib.mkOption {
      type = lib.types.str;
      default = "0";
      description = "The serial number for the zone files. Defaults to 0.";
    };
    records = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Attribute set of A records to serve.";
      # 示例: { gateway = "192.168.10.1"; nas = "192.168.10.10"; }
    };
    enableReverseZone = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to automatically generate and serve a reverse lookup zone.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.bind = {
      enable = true;
      ipv4Only = false;
      forwarders = cfg.forwarders;
      forward = "only";
      listenOn = [ cfg.listenAddress ];
      listenOnIpv6 = [ ];

      zones =
        # 正向区域
        {
          "${cfg.domain}" = {
            master = true;
            file = pkgs.writeText "${cfg.domain}.zone" generateForwardZone;
          };
        }
        # 反向区域 (可选)
        // lib.optionalAttrs (cfg.enableReverseZone) {
          "${reverseZoneName}" = {
            master = true;
            file = pkgs.writeText "${reverseZoneName}.zone" generateReverseZone;
          };
        };

      extraOptions = ''
        // Access Control
        allow-query { ${lib.concatStringsSep "; " cfg.allowQueryFrom}; };
        allow-recursion { none; };
        recursion no;

        // Security Hardening
        version "DNS Server Online";
        hostname "ns1.${cfg.domain}";
      '';
    };
  };
}
