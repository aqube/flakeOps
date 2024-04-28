# flakeOps

This repository contains experimental configuration for installing and configuring Nix systems. Currently we use it to configure a Raspberry Pi K3s managed by NixOS and our x86 server in Niedernhausen. The main goal is to create a maintainable GitOps approach for a fleet of servers and use cachix for caching and deploying on updates.

With the help of github actions, this should result in local systems that require very little manual maintenance.

# Used tools
- Home-Manager
- sops-nix
- cachix
  - cachix-deploy-flake
  - cachix binary cache
- nix-fast-build
# 🙏 Inspiration and sources
- https://gitea.muc.ccc.de/muccc/nixos-deployment

- https://nix.dev/tutorials/nixos/installing-nixos-on-a-raspberry-pi
- https://github.com/hugolgst/nixos-raspberry-pi-cluster
- https://github.com/rapenne-s/bento
- https://github.com/serokell/deploy-rs
- https://github.com/lovesegfault/nix-config
- https://haseebmajid.dev/posts/2023-11-18-how-i-setup-my-raspberry-pi-cluster-with-nixos/
- https://myme.no/posts/2022-12-01-nixos-on-raspberrypi.html#cross-compiling
- https://jamesguthrie.ch/blog/deploy-nixos-raspi/
