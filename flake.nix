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
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Cachix Deployment utils
    cachix-deploy-flake.url = "github:cachix/cachix-deploy-flake";
    cachix-deploy-flake.inputs.nixpkgs.follows = "nixpkgs";

    # flake-parts for modularizing flake.nix
    flake-parts.url = "github:hercules-ci/flake-parts";

    # run pre-commit hooks
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
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

          k3s-agent-2 = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              ./hosts/pis/k3s-agent-2/configuration.nix
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
        lib,
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
                k3s-agent-2 = self.nixosConfigurations.k3s-agent-2.config.system.build.toplevel;
              };
            };

          # sops-updatekeys = pkgs.writeShellApplication {
          #   name = "sops-updatekeys";
          #   runtimeInputs = [pkgs.sops];
          #   text = ''
          #     for secretfn in secrets/*.yaml; do
          #       sops updatekeys "$secretfn"
          #     done
          #   '';
          # };
          sops-updatekeys = with pkgs;
            runCommand "sops-updatekeys" {
              script = ./scripts/sops-updatekeys.sh;
              nativeBuildInputs = [makeWrapper];
            } ''
              makeWrapper $script $out/bin/sops-updatekeys \
                --prefix PATH : ${lib.makeBinPath [sops]}
            '';

          sops-check-encryption = with pkgs;
            runCommand "sops-check-encryption" {
              script = ./scripts/sops-check-encryption.sh;
              nativeBuildInputs = [makeWrapper];
            } ''
              makeWrapper $script $out/bin/sops-check-encryption \
                --prefix PATH : ${lib.makeBinPath [sops]}
            '';
        };

        # FIXME: our self-build shellscripts for sops-check-encryption don't work in the check sandbox on GitHub.
        # We need to define separate hook definitions for pre-commit and devShells. For now we deactivate
        # the checks but keep the pre-commit hooks.
        pre-commit = {
          check.enable = false;
          settings = {
            hooks = {
              # https://drakerossman.com/blog/overview-of-nix-formatters-ecosystem
              alejandra.enable = true;
              statix.enable = true;
              nil.enable = true;
              shellcheck.enable = true;
              sops-check-encryption = {
                enable = true;
                name = "sops-check-encryption";
                package = self'.packages.sops-check-encryption;
                description = "Check if all yaml files in ./secret are encrypted with sops";
                always_run = true;
                entry = "${self'.packages.sops-check-encryption}/bin/sops-check-encryption \"?*.yaml\" \"./secrets\"";
              };
            };
          };
        };

        # nix run
        apps = {
          sops-updatekeys = {
            type = "app";
            program = "${self'.packages.sops-updatekeys}/bin/sops-updatekeys";
          };
          sops-check-encryption = {
            type = "app";
            program = "${self'.packages.sops-check-encryption}/bin/sops-check-encryption";
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
              shellcheck
              self'.packages.sops-updatekeys
              self'.packages.sops-check-encryption
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
