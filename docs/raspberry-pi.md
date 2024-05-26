# Raspberry Pi Bootstrapping

To make use of NixOS on Raspberry Pis, you have to follow a few manual steps to get the system up and running.
In the future we have plans to build our own images to reduce the manual effort.

## 📦Install NixOS
The [official NixOS installation guide](https://nix.dev/tutorials/nixos/installing-nixos-on-a-raspberry-pi.html) is a good reference.
Download and flash the latest successful build from [Hydra](https://hydra.nixos.org/job/nixos/trunk-combined/nixos.sd_image.aarch64-linux) to an SD card and boot the Pi.

**Tip**: Use `unzstd -d` to unzip the image

After the initial boot, SSH is disabled and a few customizations are required to make the system usable.
The default configuration file of NixOS can be modified at `/etc/nixos/configuration.nix` and then the system updated with `nixos-rebuild switch`.

Initially, it's enough to enable SSH, create our default user and enable flake support. This way we can then install the Cachix Agent and use the flake in this repository to configure the system remotely. Have a look at the [pis/raspberry-pi-4.nix](../hosts/pis/raspberry-pi-4.nix) configuration for our defaults.

I tend to download (curl) the configuration file, replace the inputs, host- and username and apply the configuration with `nixos-rebuild switch` once. 

### Install Cachix Agent

We enable the Cachix agent for by default, so what is missing is only the configuration of the Cachix token.

1. [Generate an agent token and add it to 1Password](https://docs.cachix.org/deploy/running-an-agent/#generate-agent-token)
2. Create the `/etc/cachix-agent.token` file on the Pi
3. Add the Token to the file with the format `CACHIX_AGENT_TOKEN=XXX`
4. Check if you see the Cachix agent as `connected` at [our workspace](https://app.cachix.org/deploy/)

### Add the new host to the flake

We use flake-parts, but our systems obviously don't need to be built for multiple architectures.
Because of this, you just have to 

1. Create a new host configuration in the `hosts` directory.
2. Add a new `nixpkgs.lib.nixosSystem` to the `flake.nixosConfiguration` [output](https://flake.parts/options/flake-parts#opt-flake.nixosConfigurations).  See the available systems for examples, as we also add nixos-hardware modules for better Raspberry-Pi support or nix-sops. 
3. Check that you use the correct name for the configuration and import the right host configuration module. The name must match the configured Cachix agent and the hostname of the system.


