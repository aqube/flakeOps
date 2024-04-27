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
    nixpkgs.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS hardware configurations that can be imported
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # HomeManager for $HOME and user config
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Cachix for binary cache management
    cachix.url = "github:cachix/cachix";

    # sops-nix for encrypted secrets
    sops-nix.url = "github:Mic92/sops-nix";

    # Cachix Deployment and utils
    cachix-deploy-flake.url = "github:cachix/cachix-deploy-flake";
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , nixos-hardware
    , cachix
    , cachix-deploy-flake
    , sops-nix
    , ...
    } @ inputs:
    let
      system = "x86_64-linux";
      pkgs = import "${nixpkgs}" {
        inherit system;
        # ngrok, vscode, zoom-us, signal-desktop
        config.allowUnfree = true;
      };
      cachix-deploy-lib = cachix-deploy-flake.lib pkgs;
    in
    {
      # Cachix Deployments
      packages."${system}" = with pkgs; {
        cachix-deploy-spec = cachix-deploy-lib.spec {
          agents = {
            toaster = self.nixosConfigurations.toaster.config.system.build.toplevel;
            k3s-server-1 = self.nixosConfigurations.k3s-server-1.config.system.build.toplevel;
            k3s-server-2 = self.nixosConfigurations.k3s-server-2.config.system.build.toplevel;
            k3s-agent-1 = self.nixosConfigurations.k3s-agent-1.config.system.build.toplevel;
          };
        };
      };

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

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
            }
          ];
        };

        # Raspberry Pi K3s Cluster
        k3s-server-1 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./hosts/k3s-server-1/configuration.nix
            nixos-hardware.nixosModules.raspberry-pi-4
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.aqube = import ./modules/home/aqube/home.nix;
              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
            }
          ];
        };

        k3s-server-2 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./hosts/k3s-server-2/configuration.nix
            nixos-hardware.nixosModules.raspberry-pi-4
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.aqube = import ./modules/home/aqube/home.nix;
              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
            }
          ];
        };

        k3s-agent-1 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./hosts/k3s-agent-1/configuration.nix
            nixos-hardware.nixosModules.raspberry-pi-4
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.aqube = import ./modules/home/aqube/home.nix;
              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
            }
          ];
        };
      };
    };
}
