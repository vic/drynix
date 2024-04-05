top@{lib, config, ...}: let

  inherit (builtins) match;
  inherit (lib) mkOption types elemAt mapAttrs mapAttrs' literalExample pipe mapAttrsToList attrNames; 
  inherit (config.drynix.lib) paths;

  features = homeName: homeCfg: let
    importFeature = name: _: {
      imports = [ top.config.flake.homeFeatures.${name} ];
      config.features.${name}.enable = lib.mkDefault true;
    };
  in map importFeature homeCfg.enableFeatures;

  maybeMod = mod: if builtins.isAttrs mod then [mod]
    else if builtins.isFunction mod then [mod]
    else if builtins.pathExists mod then [mod]
    else [];

  mkHomeModule = (homeName: homeCfg: _: let 
    # Prepend home-manager path before system path.
    # See https://github.com/nix-community/home-manager/issues/3324
    # Remove when this gets merged: https://github.com/nix-community/home-manager/pull/4582
    prependPathModule = {lib, pkgs, config, ...}: {
      config = lib.mkMerge [
        (lib.mkIf config.programs.bash.enable {
          programs.bash.initExtra = "export PATH=$HOME/.local/state/nix/profiles/home-manager/home-path/bin:/run/wrappers/bin:/run/current-system/sw/bin:$PATH";
        })
        (lib.mkIf config.programs.zsh.enable {
          programs.zsh.initExtra = "export PATH=$HOME/.local/state/nix/profiles/home-manager/home-path/bin:/run/wrappers/bin:/run/current-system/sw/bin:$PATH";
        })
        (lib.mkIf config.programs.fish.enable {
          programs.fish.shellInit = "set -x PATH $HOME/.local/state/nix/profiles/home-manager/home-path/bin /run/wrappers/bin /run/current-system/sw/bin $PATH";
        })
      ];
    };
  in {
      options.features = {};
      config._module.args.flakeConfig = top.config;
      imports = [prependPathModule] ++ (maybeMod homeCfg.homeModule) ++ features homeName homeCfg;
    });

  mkHomeConfiguration = homeName: homeCfg: homeCfg.builder {
    modules = [ 
      top.config.flake.homeModules.${homeName} 
    ];
    pkgs = homeCfg.pkgs;
  };

in { 
  options.drynix.home-configurations = mkOption {
    description = "home-manager configurations.";
    type = types.lazyAttrsOf (types.submodule ({name, config, ...}: {
      options = {
        builder = mkOption {
          description = "function used to build a hm-configuration";
          example = literalExample "inputs.home-manager.lib.homeManagerConfiguration";
          default = top.config.drynix.inputs.home-manager.lib.homeManagerConfiguration;
        };
        userName = mkOption { 
          default = elemAt (match "([^@]+)@(.*)" name) 0;
        };
        hostName = mkOption {
          default = elemAt (match "([^@]+)@(.*)" name) 1;
        };
        userModule = mkOption {
          description = "nixos user module";
          default = paths.homes.user name;
        };
        hostModule = mkOption {
          description = "nixos system module";
          default = paths.homes.host name;
        };
        homeModule = mkOption {
          description = "home-manager module to configure the user home.";
          default = paths.homes.configuration name;
        };
        pkgs = mkOption {
          description = "nixpkgs instance to use for homeConfiguration";
          default = null;
        };
        enableFeatures = mkOption {
          description = "features to enable from homeFeatures.";
          default = [];
          type = types.listOf (types.enum (attrNames top.config.flake.homeFeatures));
        };
      };
    }));
  };

  config = {
    flake.homeModules = mapAttrs mkHomeModule config.drynix.home-configurations;
    flake.homeConfigurations = mapAttrs mkHomeConfiguration config.drynix.home-configurations;
  };
}
