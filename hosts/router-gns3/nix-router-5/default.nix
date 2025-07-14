{
  pkgs,
  ...
}:
{
  imports = [
    ./../../nix-router-base/disk.nix
    ./../../nix-router-base/networking.nix
    ./../../nix-router-base/set-dynamic-hostname.nix
  ];

  system.stateVersion = "24.11";
}
