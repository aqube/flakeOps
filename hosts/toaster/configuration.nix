{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # FIXME: use a more elegant mechanism to include modules
    ../../modules/nixos
  ];

  # custom modules configuration
  modules.services.k3s = {
    enable = true;
    role = "database";
  };

  # Bootloader.
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = true;
  };

  services = {
    # cachix deploy agent
    cachix-agent.enable = true;
    # Enable the OpenSSH daemon.
    openssh.enable = true;
    # Configure keymap in X11
    xserver.xkb = {
      layout = "us";
      variant = "";
    };
  };

  networking.hostName = "toaster"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  nix.settings = {
    # give the users in this list the right to specify additional substituters via:
    #    1. `nixConfig.substituters` in `flake.nix`
    #    2. command line args `--options substituters http://xxx`
    trusted-users = ["aqube"];
    substituters = [
      "https://cache.nixos.org"
      "https://aqube.cachix.org"
    ];
    trusted-public-keys = [
      "aqube.cachix.org-1:ERe7jQ/KiuBHmvNIO8cAxIptfvqDEmw5CWrqXpfWId0="
    ];
    # Enable Flakes
    experimental-features = ["nix-command" "flakes"];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.aqube = {
    isNormalUser = true;
    description = "aqube";
    extraGroups = ["networkmanager" "wheel"];
    openssh.authorizedKeys.keys = [
      # alex
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIu53Qed8bnM/iV/ilBYwYSpGHdq2t3Fiogk3epOGg1K"
      # adrian
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDeLaFzUE6ppV0CTl4YG0gsS4lGvnX8At4NxMgWJGz0Mjp7tr+0i35XhxH6F+bUSndjgFFHf6/+OsAK6/MYzaEtvNxjSofatUtulSWoYVvquE6sQZQA1ByOfgrD75h5NmFumEqouxsrrj6LfdM3FOJUCnelBVt6Ei71ofxUAnqX9cOUCJV3qXalhEumH8kk92uvl6FKrhVHGFLbn7tEw8vEvWPbJ17P5PQtcHImAGoII6ulbK7IkoTfHf18ZYvV5YAHxWRFs6jUzooxk0p2DhclFZuRKSVDma27zbnInN68F+/wP6l1IMYCXri7uhYkLAVQfTDAY4+IKgGeyNOF9e0xRJGhVS1wDq2jUA9OtM0l3w/YBSJIFgUpleoyJ2fs7IEZcHEpn7p0PURDjl5mNDvPzQSjNqTj6I2n39W5eSDXceEiRqHMncxyeFXRbI6/+f/RC45TzIdxXvwZQO4bu2QTJVuVGrrEOrzi06EYUDuEWDBsi5RpNbtIsaEXlMF8VgUPIXANEejF/X/+STqAgy5nJufBasKYPyo7Z8V1S/RLW8+Nm/kZErsPuy0ws2rwmCxE6Fs9XjhQfE4znk+DLZD2YgdmqFVzssX/IHA66OglHvBiGvh+kjbER4MN2NT1zAozcLZWZOOEG/1zUbq2jSj7a0KfAJqnNgJbLBuuxR8XVQ=="
      # maxi
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCZlc/elW2kWPiypxEM5pfK+VZWfWkhzodJojMHa1VGrI7D5rZfU7Co3zJ28s4c8vOuk5eyOOQ97XMalvssCl/yT5GvGuybYYpclbfaVAkzvly0oS/VCpeZ6psTYri2vR97fwEnQvPdSKZOmX7MNzlm0mV2KmQfAKl2z3gcZRomas07xHUMGtlYADd9g8SaHFnbX0bGBlfGIwy2atp3PmmfUKLiQLd+RYfhvPJtwDdGQFC1Z/dxteycCWQdRmzvI5y7w+8xM76ACFS/HQrkIiAic7q2A8aSecn+oNXe8EDPmKAi7W1NezwIPZl/vaO0hxbBcexcYSDe9X3WPEzDY9kxgXwXGU9WNdZefH2QaV5hk+10wjZ2OVFknLH2FiWS3WgTwt87KdRZV0Uu12MvvMma1J+DtQ0ImIEjc77yCy1FK5ReGdNi4cT1f1IojeWOffPm16uwS0YJYPowTBeMkltaw+d52K+qFGKTf7l/WH/IrOpMYX2qA1ANDHByx+evrlNTz+UFR4fW41fhpfOKYaBARAX1vMEfrDya0LP2G9qzHRjmE/2aKmYOa15+RpRKNYxpx+FzHCNPzOknEinznHNwAy50om94Pz+zuc5CxEnBTFTMkWo5N/EQh0/TSm9Y/iXo2hqV4oPv6LRkkYMk4GBu7M/Fv8u6F50NdI2pLXIhQ=="
      # yorrick
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDXTUJ73E0QYOCau+cA2cenrekk0RQpqrywXxbTMGHcDd7blH1AFnnKF2H5kmHPOPaLRlqosvuCNvsbg/+FYRuTTuGamxmjet8xzVWQpg6Abd0la0dEI9JnRsV9BAh6ebIwkotCxZhIqR5uBbFQptM9WyKUuGFVA9CsgBCKCTkMLb/ppTFUD0M+H4JetbxsIGjGYppKXnkr31hCr9RvT3Sw2jZ3dahkYb+o5cM7wQUIIis1eplfVAkoSXZGvSf26fIHs1n1OkHKxhFZuIarEURIVll6ynJENMbMidAb9K8bl/6jSv49DW6muJWyWhztAVr4NLTrkHbe5prBrllcELzf5QgUbLFpZfaPTaQfYlphNsqxxGRjrEYR0VVk1PB6IRSQa9qMq1n45GcNlL0yf/friQisiv6km/qJjuZk36YsUTpWTlVrnZCV8Nno0BvSTK7JbPUIwUWhPDwmtcevZONomsWgbncnil1jRq1llr7/rJ+sjwDT46pv1yXavXm43I+6SHMpsoxdbUWvkxwtIGkQzOgDYyzXEc9NpsVBQrM6OYaR18SSMBDR9huTrmVYPi2Cj0C+CO77hg47EJtF1BAdBaVg0aL4PuF850u2yWdsSHcZ2SH0EPfv2en853JPfHMAUE4c24j0HONgpxUk+VMq3Q1BCS2UzGyxrgvVclRO+Q=="
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  security.sudo.wheelNeedsPassword = false;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
