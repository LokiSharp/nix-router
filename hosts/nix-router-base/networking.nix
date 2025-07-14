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
        networkConfig = {
          DHCP = "yes";
        };
      };

      "20-wan0" = {
        matchConfig.Name = "wan0";
        networkConfig = {
          DHCP = "yes";
        };
      };

      "99-lan" = {
        matchConfig.Name = "enp*s*";
        networkConfig = {
          Bridge = "br-lan";
        };
      };

      "30-br-lan" = {
        matchConfig.Name = "br-lan";
      };
    };
  };
}
