# Modules

Modules are re-usable pieces of configuration. 
With Nix(OS) there are multiple types of modules and we 
separate them, because they are loaded differently.

## Structure
```
`home/user`: Modules for [home-manager](https://github.com/nix-community/home-manager). Configuration for your `$HOME` folder. Very user specific.
`nixos`: Modules for NixOs. These configurations are usually system-wide and not restricted to a specific user.
`darwin`: Modules for [nix-darwin](https://github.com/LnL7/nix-darwin) systems.
```