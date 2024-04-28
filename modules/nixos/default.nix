{ config, pkgs, ... }:

{
  imports =
    [
      ./services/postgresql.nix
      ./services/k3s.nix
    ];
}
