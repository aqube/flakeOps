{
  description = "NixOS configurations, multiarch, build on Github, weekly updates, continuous deployments";
  nixConfig = {
    # substituers will be appended to the default substituters when fetching packages
    extra-substituters = [
      "https://aqube.cachix.org"
    ];
    extra-trusted-public-keys = [
      "aqube.cachix.org-1:ERe7jQ/KiuBHmvNIO8cAxIptfvqDEmw5CWrqXpfWId0="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # NixOS hardware configurations that can be imported
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # HomeManager for $HOME and user config
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # sops-nix for encrypted secrets
    sops-nix.url = "github:Mic92/sops-nix";

    # Cachix Deployment utils
    cachix-deploy-flake.url = "github:cachix/cachix-deploy-flake";

    # flake-parts for modularizing flake.nix
    flake-parts.url = "github:hercules-ci/flake-parts";

  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , nixos-hardware
    , cachix
    , cachix-deploy-flake
    , sops-nix
    , flake-parts
    , ...
    } @ inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # https://flake.parts/debug
      debug = true;

      # Original Flake Attributes
      flake = {

        nixosConfigurations = {
          # Toaster is a Lenovo ThinkBox with NixOs installed. Currently sitting as a x86 server in the
          # basement in Niedernhausen.
          toaster = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./hosts/toaster/configuration.nix
              sops-nix.nixosModules.sops
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.aqube = import ./modules/home/aqube/home.nix;
              }
            ];
          };

          # Raspberry Pi K3s Cluster
          k3s-server-1 = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              ./hosts/pis/k3s-server-1/configuration.nix
              nixos-hardware.nixosModules.raspberry-pi-4
              sops-nix.nixosModules.sops
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.aqube = import ./modules/home/aqube/home.nix;
              }
            ];
          };

          k3s-server-2 = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              ./hosts/pis/k3s-server-2/configuration.nix
              nixos-hardware.nixosModules.raspberry-pi-4
              sops-nix.nixosModules.sops
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.aqube = import ./modules/home/aqube/home.nix;
              }
            ];
          };

          k3s-agent-1 = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              ./hosts/pis/k3s-agent-1/configuration.nix
              nixos-hardware.nixosModules.raspberry-pi-4
              sops-nix.nixosModules.sops
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.aqube = import ./modules/home/aqube/home.nix;
              }
            ];
          };
        };
      };

      # Configure the Systems that you want to build the `perSystem` attributes for
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];

      # perSystem has some special module parameters. e.g pkgs == inputs.nixpkgs.legacyPackages.${system}.
      # https://flake.parts/module-arguments#persystem-module-parameters
      perSystem = { self', system, config, pkgs, ... }: {

        # TODO: find a way how I can build aarch64-darwin and x86_64-darwin on github actions
        packages = {
          # Cachix Deployments
          # TODO: understand how "...config.system.build.toplevel" interprets the "system" part
          # Is this from let system = "x86_64-linux" or from the nixosSystem.system attribute?
          cachix-deploy-spec =
            let
              # FIXME: if this runs in CI, remove it. We can use the pkgs parameter from perSystem
              # pkgs = import nixpkgs { inherit system; };
              cachix-deploy-lib = cachix-deploy-flake.lib pkgs;
            in
            cachix-deploy-lib.spec {
              agents = {
                toaster = self.nixosConfigurations.toaster.config.system.build.toplevel;
                k3s-server-1 = self.nixosConfigurations.k3s-server-1.config.system.build.toplevel;
                k3s-server-2 = self.nixosConfigurations.k3s-server-2.config.system.build.toplevel;
                k3s-agent-1 = self.nixosConfigurations.k3s-agent-1.config.system.build.toplevel;
              };
            };

          sops-updatekeys = pkgs.writeShellApplication {
            name = "sops-updatekeys";
            runtimeInputs = [ pkgs.sops ];
            text = ''
              for secretfn in secrets/*.yaml; do
                sops updatekeys "$secretfn"
              done
            '';
          };
        };

        # nix run
        apps = {
          sops-updatekeys = {
            type = "app";
            program = "${self'.packages.sops-updatekeys}/bin/sops-updatekeys";
          };
        };

        # nix develop
        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              age
              sops
              nil
              self'.packages.sops-updatekeys
            ];
          };
        };

      };
    };
}
