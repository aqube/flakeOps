{ config, pkgs, ... }:
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = "aqube";
    homeDirectory = "/home/aqube";

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "23.11";
  };


  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs = {
    bash = {
      enable = true;
      enableCompletion = true;
      shellAliases = {
        ll = "ls -lh";
        la = "ls -a";
        lla = "ls -la";
      };
    };

    fzf = {
      enable = true;
      enableBashIntegration = true;
    };

    # Better Terminal
    starship = {
      enable = true;

      enableBashIntegration = true;
      enableZshIntegration = true;

      settings =
        {
          character = {
            success_symbol = "[›](bold green)";
            error_symbol = "[›](bold red)";
          };
        };
    };
  };

}
