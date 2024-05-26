{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.services.k3s;
in {
  options.modules.services.k3s = {
    enable = mkEnableOption "Lightweight Kubernetes Distribution";

    role = mkOption {
      type = types.enum ["server" "agent" "database"];
      default = "server";
      description = "The type of K3s service to enable. One of 'server', 'agent' or 'database'. Default: 'server'";
    };
  };

  config = mkIf cfg.enable {
    # Database
    # TODO: create user with nix-sops password (seems to be hard)
    # TODO configure backups to NAS
    services.postgresql = mkIf (cfg.role == "database") {
      enable = true;
      # pin it to prevent postgres version upgrades
      package = pkgs.postgresql_15;
      ensureDatabases = ["K3s"];
      enableTCPIP = true;

      authentication = pkgs.lib.mkOverride 10 ''
        # TYPE  DATABASE  USER  ADDRESS           METHOD
          local all       all                     trust
        # ipv4
          host  all       all   192.168.178.0/32  trust
          host  all       all   192.168.192.0/32  trust
      '';
    };

    # Configure Token to join Nodes
    sops = {
      defaultSopsFile = ../../../secrets/k3s.yaml;
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      secrets."k3s/server/token" = {};
    };
  };
}
