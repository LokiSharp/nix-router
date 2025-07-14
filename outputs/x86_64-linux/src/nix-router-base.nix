{
  # NOTE: the args not used in this file CAN NOT be removed!
  # because haumea pass argument lazily,
  # and these arguments are used in the functions like `mylib.nixosSystem`, `mylib.colmenaSystem`, etc.
  inputs,
  lib,
  myvars,
  mylib,
  system,
  genSpecialArgs,
  ...
}@args:
let
  hostName = "Nix-Router-Base";
  hostNameLower = lib.toLower hostName;
  tags = [
    hostName
    hostNameLower
    "router"
    "router-base-image"
  ];
  ssh-user = "root";

  modules = {
    nixos-modules = (
      map mylib.relativeToRoot [
        # common
        "modules/nixos/server.nix"
        "modules/nixos/hardware-configuration/qemu-hardware-configuration.nix"
        # host specific
        "hosts/${hostNameLower}"
      ]
    );
  };

  systemArgs = modules // args;
in
{
  nixosConfigurations.${hostName} = mylib.nixosSystem systemArgs;

  colmena.${hostName} = mylib.colmenaSystem (systemArgs // { inherit tags ssh-user; });

  packages.${hostName} = inputs.self.nixosConfigurations.${hostName}.config.formats.qcow-efi;
}
