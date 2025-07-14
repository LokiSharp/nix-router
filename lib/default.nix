{
  config ? { },
  pkgs ? { },
  lib ? pkgs.lib,
  self ? null,
  ...
}:
let
  call =
    path:
    builtins.removeAttrs (lib.callPackageWith (pkgs // helpers) path { }) [
      "override"
      "overrideDerivation"
    ];
  helpers = rec {
    inherit
      config
      pkgs
      lib
      ;

    withConfig =
      newConfig:
      import ./. {
        inherit
          pkgs
          lib
          self
          ;
        config = newConfig;
      };

    colmenaSystem = import ./system/colmenaSystem.nix;
    nixosSystem = import ./system/nixosSystem.nix;

    attrs = import ./fn/attrs.nix { inherit lib; };
    serviceHarden = call ./fn/service-harden.nix;
    tools = call ./fn/tools.nix;

    # use path relative to the root of the project
    relativeToRoot = lib.path.append ../.;
    scanPaths =
      path:
      builtins.map (f: (path + "/${f}")) (
        builtins.attrNames (
          lib.attrsets.filterAttrs (
            path: _type:
            (_type == "directory") # include directories
            || (
              (path != "default.nix") # ignore default.nix
              && (lib.strings.hasSuffix ".nix" path) # include .nix files
            )
          ) (builtins.readDir path)
        )
      );
  };
in
helpers
