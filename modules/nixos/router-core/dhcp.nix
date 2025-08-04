{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.routerCore.dhcp;
in
{
  options.routerCore.dhcp = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable the dnsmasq DHCP server.";
    };

    interface = lib.mkOption {
      type = lib.types.str;
      default = "br-lan";
      description = "The network interface to listen on.";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "lan";
      description = "The local network domain.";
    };

    pool = lib.mkOption {
      type = lib.types.submodule {
        options = {
          start = lib.mkOption {
            type = lib.types.str;
            description = "The starting IP address of the DHCP pool.";
          };
          end = lib.mkOption {
            type = lib.types.str;
            description = "The ending IP address of the DHCP pool.";
          };
          gateway = lib.mkOption {
            type = lib.types.str;
            description = "The default gateway for clients.";
          };
        };
      };
      description = "DHCP address pool configuration.";
    };

    dnsServers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ cfg.pool.gateway ]; # 默认使用网关作为DNS服务器
      description = "List of DNS servers to provide to clients.";
    };

    staticHosts = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Hostname";
            };
            ip = lib.mkOption {
              type = lib.types.str;
              description = "Static IP address";
            };
          };
        }
      );
      default = [ ];
      description = "List of static IP assignments for specific hosts.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.dnsmasq = {
      enable = true;
      settings = {
        # 接口配置
        interface = cfg.interface;
        bind-interfaces = true;

        # DHCP地址池配置 (使用 cfg.pool 中的值)
        dhcp-range = [ "${cfg.pool.start},${cfg.pool.end},12h" ];
        dhcp-authoritative = true;

        # 网络选项配置 (动态生成)
        dhcp-option =
          [ "option:router,${cfg.pool.gateway}" ] # 默认网关
          ++ (map (dns: "option:dns-server,${dns}") cfg.dnsServers) # DNS服务器列表
          ++ [ "option:domain-name,${cfg.domain}" ]; # 域名后缀

        # 静态IP分配 (将我们的结构化列表转换为 dnsmasq 需要的格式)
        dhcp-host = map (host: "${host.name},${host.ip}") cfg.staticHosts;

        # 服务配置
        port = 0; # 禁用DNS(假设由其他服务如BIND处理)
        log-dhcp = true;
        log-facility = "/var/log/dnsmasq.log";

        # 域名配置
        local = "/${cfg.domain}/";
        domain = cfg.domain;
        expand-hosts = true;
      };
    };
  };
}
