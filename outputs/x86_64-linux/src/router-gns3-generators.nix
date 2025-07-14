# 生成 router-gns3 配置的函数
{
  lib,
  mylib,
  inputs,
  myvars,
  system,
  genSpecialArgs,
  ...
}@args:

let # 生成单个路由器配置的函数
  makeRouterConfig =
    routerIdentifier:
    let
      hostName = "Nix-Router-${toString routerIdentifier}";
      hostNameLower = lib.toLower hostName;

      tags =
        [
          hostName
          hostNameLower
          "router"
          "router-gns3"
        ]
        ++ (
          if routerIdentifier == "Core" then
            [
              "gateway"
              "dhcp"
            ]
          else
            [ ]
        );

      ssh-user = "root";

      modules = {
        nixos-modules = (
          map mylib.relativeToRoot [
            # common
            "modules/nixos/server.nix"
            "modules/nixos/hardware-configuration/qemu-hardware-configuration.nix"
            # host specific - 每个路由器有自己的配置文件
            "hosts/router-gns3/${hostNameLower}"
          ]
        );
      };

      systemArgs = modules // args;

      nixosConfig = mylib.nixosSystem systemArgs;
    in
    {
      ${hostName} = {
        nixosConfiguration = nixosConfig;
        colmenaConfiguration = mylib.colmenaSystem (systemArgs // { inherit tags ssh-user; });
        package = nixosConfig.config.formats.qcow-efi;
      };
    };

  # 路由器标识符列表（包含数字和字符串）
  routerIdentifiers = [
    1
    2
    3
    4
    5
    "Core"
  ];

  # 生成所有路由器配置
  allRouterConfigs = lib.attrsets.mergeAttrsList (map makeRouterConfig routerIdentifiers);

  # 提取所有 nixosConfigurations
  nixosConfigurations = lib.mapAttrs (name: config: config.nixosConfiguration) allRouterConfigs;

  # 提取所有 colmena 配置
  colmena = lib.mapAttrs (name: config: config.colmenaConfiguration) allRouterConfigs;

  # 提取所有 packages
  packages = lib.mapAttrs (name: config: config.package) allRouterConfigs;

in
# 返回正确结构的配置
{
  inherit nixosConfigurations colmena packages;
}
