{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./services/k3s.nix
  ];
}
