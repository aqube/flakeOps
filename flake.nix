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

    # run pre-commit hooks
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixos-hardware,
    cachix,
    cachix-deploy-flake,
    sops-nix,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      # https://flake.parts/debug
      debug = true;

      imports = [
        inputs.pre-commit-hooks-nix.flakeModule
      ];

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
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  users.aqube = import ./modules/home/aqube/home.nix;
                };
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
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  users.aqube = import ./modules/home/aqube/home.nix;
                };
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
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  users.aqube = import ./modules/home/aqube/home.nix;
                };
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
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  users.aqube = import ./modules/home/aqube/home.nix;
                };
              }
            ];
          };
        };
      };

      # Configure the Systems that you want to build the `perSystem` attributes for
      systems = ["x86_64-linux" "x86_64-darwin" "aarch64-darwin"];

      # TODO: cross-compilation and emulated builds are tricky. They can result in different hashes and this
      # would turn the build derivations useless, as they won't be downloaded from aqube.cachix.org
      # Understand this in details is crucial for the quality of this repo.
      # - https://discourse.nixos.org/t/cross-compiling-a-devshell/23084/7

      # perSystem has some special module parameters. e.g pkgs == inputs.nixpkgs.legacyPackages.${system}.
      # https://flake.parts/module-arguments#persystem-module-parameters
      perSystem = {
        self',
        system,
        config,
        pkgs,
        ...
      }: {
        packages = {
          # Cachix Deployments
          # TODO: understand how "...config.system.build.toplevel" interprets the "system" part
          # Is this from let system = "x86_64-linux" or from the nixosSystem.system attribute?
          cachix-deploy-spec = let
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

          # TODO: outsource the sops-updatekeys script
          sops-updatekeys = pkgs.writeShellApplication {
            name = "sops-updatekeys";
            runtimeInputs = [pkgs.sops];
            text = ''
              for secretfn in secrets/*.yaml; do
                sops updatekeys "$secretfn"
              done
            '';
          };
        };

        pre-commit = {
          settings = {
            hooks = {
              # https://drakerossman.com/blog/overview-of-nix-formatters-ecosystem
              alejandra.enable = true;
              statix.enable = true;
              nil.enable = true;
              markdownlint.enable = true;
            };
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
              statix
              alejandra
              self'.packages.sops-updatekeys
            ];
            shellHook = ''
              ${config.pre-commit.installationScript}
              echo 1>&2 "Welcome to the development shell!"
            '';
          };
        };
      };
    };
}
