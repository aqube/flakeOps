# Bootstrap

This part needs more refinement. Right now, I have a self-build image in mind, that adds basic configuration like 

- enabled ssh
- ssh-pub keys
- flake support enabled
- and required configurations for k3s

to the newest NixOS AArch64 Hydra build. https://hydra.nixos.org/job/nixos/trunk-combined/nixos.sd_image_raspberrypi4.aarch64-linux/all?page=1

## Manual

1. Download and flash image
2. Boot and run `nixos-generate-configuration`
3. Update configuration.nix and flake.nix with custom ones
