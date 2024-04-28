# flakeOps

> [!NOTE]
> This repo contains the declarative configuration of aqube's on-premise infrastructure. We are still adopting the Nix ecosystem and this repository is a work in progress. We are happy to receive feedback and suggestions.

## Introduction

We started to play around with parts of the Nix ecosystem in early 2024 as an alternative to our more CNCF oriented configuration management. Till then, we used a combination of Ansible, Terraform a lot of scripting and GitOps for hard- and software deployments. Something that's hard to maintain and not as declarative as we would like it to be.

As we are already heavily invested in GitOps for our K8s clusters and customer projects, we wanted to extend this to our on-premise infrastructure as well. The additional benefit of using Nix for development environments and our workstations was a nice side effect.

With the help of github actions for automatic dependency updates, builds and deployments, this should result in local systems that require very little manual maintenance.

## Inputs and Tools
We use a couple of upstream inputs and tools for our flake. The main ones are:

- [home-manager](https://github.com/nix-community/home-manager) for `$HOME` directory management as module for NixOs or nix-darwin.
- [sops-nix](https://github.com/Mic92/sops-nix) to encrypt the few static secrets we need for our deployments. Usually we use a combination of [1password](https://1password.com/) products for dynamic secrets.
- Cachix tools:
  - [cachix-action](https://github.com/cachix/cachix-action) to store our outputs in a public `aqube` binary cache.
  - [cachix-deploy-flake](https://github.com/cachix/cachix-deploy-flake) to generate a `cachix-deploy.json` for all our [cachix-deploy](https://docs.cachix.org/deploy/) agents.
  - [pre-commit-hooks](https://github.com/cachix/pre-commit-hooks.nix) to integrate pre-commit-hooks with flake.

### Under Consideration
- [nix-fast-build](https://github.com/Mic92/nix-fast-build) to speed up the build process on the CI. More useful if we start to build more configurations for different systems. (MultiArch)
- [nixos-generators](https://github.com/nix-community/nixos-generators) to generate Images for our Raspberry Pi's and other devices (RISC-V).
- [flake-utils](https://github.com/numtide/flake-utils) or [flake-utils-plus](https://github.com/gytis-ivaskevicius/flake-utils-plus) to simplify multi-arch builds. But we would need to test how it works in combination with cachix-deploy.
- [flake-parts](https://github.com/hercules-ci/flake-parts) to split our flake into smaller parts. This would make it easier to maintain and test the different parts of our infrastructure.
- [nix-direnv](https://github.com/nix-community/nix-direnv) to use direnv with nix. This would make it easier to work with this repository by automatically activating a devshell with all required tools.

# Usage

## Secrets

We use [sops-nix](https://github.com/Mic92/sops-nix) to encrypt secrets. This allows us to use sops for secrets management, including all available backends. The access configuration is configured in the [.sops.yaml](./.sops.yaml) file. The secrets are stored in the [secrets](./secrets) directory.

Because we also store the secrets encrypted in the repository, it's then also encrypted in the cachix binary cache. This way, we can use the secrets in the deployment process without exposing them.

### Add a new secret
1. If the target host is new, generate a age-key for it. If possible from an existing ssh-key.
    ```bash
    nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
    ```
2. Add the key to the encryption configuration in the `.sops.yaml` file and re-encrypt all secrets with the new keys. We plan to add a command to automate this with `mkApp` in the future.
    ```bash
    # repeat this for all secrets
    nix-shell -p sops --run "sops updatekeys secrets/<secret>"
    ```
3. Create a new secret file in the [secrets](./secrets) directory and encrypt it.
4. Add the secret to a host configuration. This requires a module configuration for the `sops-nix` options. We often create a age-key for the host from the host's ssh-key. This way, we can use the host's ssh-key to decrypt the secrets. If that's the case, add the `sops.age.sshKeyPaths` to the host configuration. Secrets are then defined in the `secrets` attribute. Be careful to use `/` as separators for the specific secrets path and **not** a `.` like in yaml syntax! The secret will then be available in a file on the host at `/run/secrets/<secret-path>`. 

    Example:

    ```nix
        sops = {
            defaultSopsFile = ../../../secrets/<secret-file-name>.<extension>;
            age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            secrets."k3s/server/token" = { };
        };
    ```

## 🙏 Inspiration

### The Great ❤️
- [NixOS & Flakes ](https://nixos-and-flakes.thiscute.world/preface) - Great Book from [ryan4yin](https://github.com/ryan4yin) that gives a great introduction to NixOS and Flakes.

### References
- [Noogle](https://noogle.dev/) - function reference
- [MyNixOS](https://mynixos.com/)
- [Awesome Nix](https://github.com/nix-community/awesome-nix)

### Official Documentation
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [Nix Language](https://nixos.org/manual/nix/stable/language/)
- [Nix Dev](https://nix.dev/)

### Examples

- [ryan4yin NixOs Config](https://github.com/ryan4yin/nix-config) - Extensive configuration for a fleet of machines. Including Builder-Pattern and deployments with colema.
- [MUC Nix Configuration](https://gitea.muc.ccc.de/muccc/nixos-deployment) - A great example of a NixOS deployment configuration from the CCC Munich.
- [lovesegfault/nix-config](https://github.com/lovesegfault/nix-config)
- [hlissner/dotfiles](https://github.com/hlissner/dotfiles) - [Hey](https://www.youtube.com/watch?v=ZZ5LpwO-An4), it's a Nix configuration repo from one of the nicest people in the Nix/Emacs community.

### Misc

- [Nix Pills](https://nixos.org/guides/nix-pills/index.html) - a bit outdated
- https://github.com/hugolgst/nixos-raspberry-pi-cluster
- https://haseebmajid.dev/posts/2023-11-18-how-i-setup-my-raspberry-pi-cluster-with-nixos/
- https://myme.no/posts/2022-12-01-nixos-on-raspberrypi.html#cross-compiling
- https://jamesguthrie.ch/blog/deploy-nixos-raspi/
