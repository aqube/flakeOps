{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.services.k3s;
in
{
  options.modules.services.k3s = {
    enable = mkEnableOption "Lightweight Kubernetes Distribution";
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../../secrets/k3s.yaml;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      secrets."k3s.server.token" = { };
    };
  };
}
