# colmena - Remote Deployment via SSH
{
  lib,
  inputs,
  nixos-modules,
  myvars,
  system,
  targetHost ? null,
  ssh-user,
  genSpecialArgs,
  specialArgs ? (genSpecialArgs system),
  tags ? [ ],
  ...
}:
{ name, ... }:
{
  deployment = {
    targetUser = ssh-user;
    targetHost = if targetHost == null then name else targetHost; # hostName or IP address
    tags = tags;
  };

  imports = nixos-modules;
}
