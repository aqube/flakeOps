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

    cachix.url = "github:cachix/cachix";

    # flake-utils manage system builds and can help to build the
    # same flake for different systems. (e.g. x86_64-linux and aarch64-linux)
    # FIXME: check if this can be used
    # inputs.systems.url = "github:nix-systems/x86_64-linux";
    # flake-utils.url = "github:numtide/flake-utils";
    # We currently only deploy to "toaster" and only need x86_64-linux
    # This way "eachDefaultSystem" will only build for x86_64-linux
    # FIXME: this is a workaround till we also deploy to the Raspberry Pis
    # inputs.flake-utils.inputs.systems.follows = "systems";

    # Cachix Deployment and utils
    cachix-deploy-flake.url = "github:cachix/cachix-deploy-flake";

    # Colmena for external deployment from a dedicated host machine
    # TODO: replace this with cachix agents/deploy
    colmena.url = "github:zhaofengli/colmena";
  };

  outputs = { self, nixpkgs, home-manager, colmena, nixos-hardware, flake-utils, cachix, cachix-deploy-flake, ... }@inputs:
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


      # colmena external deployment output
      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-darwin";
          };
        };

        defaults = { pkgs, ... }: {
          imports = [
            inputs.nixos-hardware.nixosModules.raspberry-pi-4
            ./hosts/pis/defaults.nix
          ];
        };

        meepo-1 = {
          imports = [ ./hosts/pis/meepo-1.nix ];

          nixpkgs.system = "aarch64-linux";

          deployment = {
            targetHost = "meepo-1";
            targetUser = "aqube";
            # TODO: do remote builds
            buildOnTarget = true;
          };
        };

        meepo-2 = {
          imports = [ ./hosts/pis/meepo-2.nix ];

          nixpkgs.system = "aarch64-linux";

          deployment = {
            targetHost = "meepo-2";
            targetUser = "aqube";
            # TODO: do remote builds
            buildOnTarget = true;
          };
        };

        meepo-3 = {
          imports = [ ./hosts/pis/meepo-3.nix ];

          nixpkgs.system = "aarch64-linux";

          deployment = {
            targetHost = "meepo-3";
            targetUser = "aqube";
            # TODO: do remote builds
            buildOnTarget = true;
          };
        };

        # deactivated because not buildable at the moment
        # meepo-4 = {
        #   imports = [
        #     (import ./hosts/pis/pi4.nix { hostname = "meepo-4"; username = "aqube"; })
        #   ];
        #
        #   nixpkgs.system = "aarch64-linux";
        #
        #   deployment = {
        #     targetHost = "meepo-4";
        #     targetUser = "aqube";
        #     # TODO: do remote builds
        #     buildOnTarget = true;
        #   };
        # };
      };
    };
}