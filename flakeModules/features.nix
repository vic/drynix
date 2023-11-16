{lib, config, flake-parts-lib, moduleLocation, ...}: let
  inherit (flake-parts-lib) mkSubmoduleOptions;
  inherit (lib) pipe id mapAttrs' attrValues mkOption mapAttrs types mkMerge;
  inherit (config.drynix.lib) dirApply;

  scanFeatures = kind: dirApply id "${config.drynix.self}/${kind}/_features";

  # stolen from flake-parts/modules/nixosModules.nix
  mkOptions = name: {
    options.flake = mkSubmoduleOptions {
      ${name} = mkOption {
        type = types.lazyAttrsOf types.unspecified;
        default = { };
        apply = mapAttrs (k: v: { _file = "${toString moduleLocation}#${name}.${k}"; imports = [ v ]; });
        description = ''
          NixOS ${name} modules.

          You may use this for reusable pieces of configuration, service modules, etc.
        '';
      };
    };
  }; 

in {
  imports = map mkOptions [
    # nixosModules already defined by flake-parts
    "wslModules"
    "darwinModules"
    "homeModules"
    "nixosFeatures"
    "darwinFeatures"
    "homeFeatures"
  ];

  config = {
    flake.nixosFeatures  = scanFeatures "nixos";
    flake.darwinFeatures = scanFeatures "darwin";
    flake.wslFeatures    = scanFeatures "wsl";
    flake.homeFeatures   = scanFeatures "homes";
  };
}