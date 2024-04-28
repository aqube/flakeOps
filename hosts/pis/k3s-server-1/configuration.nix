{ config, pkgs, lib, ... }:

let
  raspberryPi4 = import ../raspberry-pi-4.nix {
    inherit pkgs;
    hostname = "k3s-server-1";
    username = "aqube";
  };
in
{
  imports = [
    raspberryPi4
    ../../../modules/nixos
  ];

  modules.services.k3s.enable = true;
}
