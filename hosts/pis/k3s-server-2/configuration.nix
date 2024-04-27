{ config, pkgs, lib, ... }:

let
  raspberryPi4 = import ../raspberry-pi-4.nix {
    inherit pkgs;
    hostname = "k3s-server-2";
    username = "aqube";
  };
in
{
  imports = [ raspberryPi4 ];
}
