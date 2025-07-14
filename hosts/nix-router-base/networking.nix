{
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    links = {
      "10-mgnt0" = {
        matchConfig.Path = "pci-0000:02:00.0";
        linkConfig.Name = "mgnt0";
        linkConfig.AlternativeNamesPolicy = "database onboard slot path mac";
      };
      "20-wan0" = {
        matchConfig.Path = "pci-0000:02:01.0";
        linkConfig.Name = "wan0";
        linkConfig.AlternativeNamesPolicy = "database onboard slot path mac";
      };
    };

    netdevs = {
      "30-br-lan".netdevConfig = {
        Kind = "bridge";
        Name = "br-lan";
      };
    };

    networks = {
      "10-management" = {
        matchConfig.Name = "mgnt0";
        DHCP = "yes";
        dhcpV4Config = {
          UseRoutes = false; # 禁用从管理网络获取默认路由
          UseGateway = false; # 禁用从管理网络获取默认网关
        };
      };

      "20-wan0" = {
        matchConfig.Name = "wan0";
        DHCP = "yes";
      };

      "99-lan" = {
        matchConfig.Name = "enp*s*";
        networkConfig = {
          Bridge = "br-lan";
        };
      };
    };
  };
}
