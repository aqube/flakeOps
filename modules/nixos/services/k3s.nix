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

    isPrimary = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this node is the primary node in the cluster. Default: true";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Common Settings
    {
      # Configure Token to join Nodes
      sops = {
        defaultSopsFile = ../../../secrets/k3s.yaml;
        age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
        # Define the actual secrets
        secrets."k3s/token" = {};
        secrets."k3s/datastore-endpoint" = {};
        templates."k3s-server-config.yaml".content = ''
          disable-cloud-controller: true
          datastore-endpoint: "${config.sops.placeholder."k3s/datastore-endpoint"}"
          token: "${config.sops.placeholder."k3s/token"}"
        '';
      };
    }

    # K3s
    (mkIf (elem cfg.role ["server" "agent"]) {
      services.k3s = {
        enable = false;
        configPath = config.sops.templates."k3s-server-config.yaml".path;
      };
    })

    # External Database
    (mkIf (cfg.role == "database") {
      # TODO: create user with nix-sops password (seems to be hard)
      # TODO configure backups to NAS
      services.postgresql = {
        enable = true;
        # pin it to prevent postgres version upgrades
        package = pkgs.postgresql_15;
        ensureDatabases = ["K3s"];
        enableTCPIP = true;
        settings = {
          port = 5432;
        };
        authentication = pkgs.lib.mkOverride 10 ''
          # TYPE  DATABASE  USER  ADDRESS           METHOD
            local all       all                     trust
          # ipv4
            host  all       all   192.168.178.0/32  trust
            host  all       all   192.168.192.0/32  trust
        '';
      };
      networking.firewall.allowedTCPPorts = [5432];
    })
  ]);
}
