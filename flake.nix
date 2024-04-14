{
  description = "Raspberry Pi and K3s cluster config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS hardware configurations that can be imported
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # HomeManager for $HOME and user config
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Colmena for external deployment from a dedicated host machine
    # TODO: replace this with cachix agents/deploy
    colmena.url = "github:zhaofengli/colmena";
  };

  outputs = { self, nixpkgs, home-manager, colmena, ... }@inputs: {

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
