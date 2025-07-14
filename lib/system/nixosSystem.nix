{
  inputs,
  lib,
  system,
  genSpecialArgs,
  nixos-modules,
  specialArgs ? (genSpecialArgs system),
  myvars,
  ...
}:
let
  inherit (inputs)
    nixpkgs
    nixos-generators
    ;
in
nixpkgs.lib.nixosSystem {
  inherit system specialArgs;

  modules = nixos-modules ++ [
    nixos-generators.nixosModules.all-formats
  ];
}
