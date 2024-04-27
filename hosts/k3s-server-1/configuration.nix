{ config, pkgs, lib, ... }:

let
  # Define your hostname.
  hostname = "k3s-server-1";
  username = "aqube";
in
{
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  # Replacement for the hardware-configuration.nix that NixOS generates.
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  services.cachix-agent.enable = true;

  networking = {
    hostName = hostname;
  };

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.interfaces.wlan0.useDHCP = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Install system wide packages
  environment.systemPackages = with pkgs; [ git vim ];

  nix.settings = {
    # give the users in this list the right to specify additional substituters via:
    #    1. `nixConfig.substituters` in `flake.nix`
    #    2. command line args `--options substituters http://xxx`
    trusted-users = [ username ];
    substituters = [
      "https://cache.nixos.org"
      "https://aqube.cachix.org"
    ];
    trusted-public-keys = [
      "aqube.cachix.org-1:ERe7jQ/KiuBHmvNIO8cAxIptfvqDEmw5CWrqXpfWId0="
    ];
    # Enable Flakes
    experimental-features = [ "nix-command" "flakes" ];
  };

  users = {
    mutableUsers = false;
    users."${username}" = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      # Warning: This password is only used for setting up isolated and local machines
      # and removed after that.
      password = "aqube";
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
  };
  security.sudo.wheelNeedsPassword = false;

  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11"; # Did you read the comment?
}
