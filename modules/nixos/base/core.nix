{ lib, ... }:
{
  boot.loader.systemd-boot = {
    # we use Git for version control, so we don't need to keep too many generations.
    configurationLimit = lib.mkDefault 3;
  };

  boot.loader.timeout = lib.mkDefault 1; # wait for x seconds to select the boot entry
}
