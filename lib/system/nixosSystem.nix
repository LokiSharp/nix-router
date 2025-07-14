{
  inputs,
  lib,
  system,
  genSpecialArgs,
  nixos-modules,
  home-modules ? [ ],
  specialArgs ? (genSpecialArgs system),
  myvars,
  ...
}:
let
  inherit (inputs)
    nixpkgs
    home-manager
    nixos-generators
    vscode-server
    ;
in
nixpkgs.lib.nixosSystem {
  inherit system specialArgs;

  modules = nixos-modules ++ [
    nixos-generators.nixosModules.all-formats
  ];
}
