{ config, pkgs, lib, ... }:

let
  hostname = "meepo-1";
  username = "aqube";
in
{
  networking = {
    hostName = hostname;
  };

  nix.settings.trusted-users = [ hostname ];

  users = {
    users."${username}" = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      password = "aqube";
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIu53Qed8bnM/iV/ilBYwYSpGHdq2t3Fiogk3epOGg1K" ];
    };
  };

  environment.systemPackages = with pkgs; [
    python3
  ];
}
