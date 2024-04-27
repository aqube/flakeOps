{ config, pkgs, ... }:

{
  imports =
    [
      ./services/postgresql.nix
    ];
}
