{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.services.postgresql;
in
{
  options.modules.services.postgresql = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "mydatabase" ];
      authentication = mkOverride 10 ''
        #type database  DBuser  auth-method
        local all       all     trust
      '';
    };
  };
}
