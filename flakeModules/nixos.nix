top@{lib, config, ...}: let
  inherit (lib) mkOption types pipe listToAttrs mapAttrsToList mapAttrs flatten optional literalExample mkDefault length pathExists;
  inherit (config.drynix.lib) paths;

  mod = import ./_nixos_builder top {
    kind = "nixos";

    builder = {config, ...}: {
      fn = {
        default = config.inputs.nixpkgs.lib.nixosSystem;
        example = literalExample "inputs.nixpkgs.lib.nixosSystem";
      };

      hm = {
        default = config.inputs.home-manager.nixosModules.home-manager;
        example = literalExample "inputs.home-manager.nixosModules.home-manager";
      };

      extraMods = name: {
        default = []; 
        example = literalExample "[]";
      };
    };
  };


in {
  options.drynix.nixos-configurations = mod.options.configurations;
  config = {
    flake.nixosModules = mod.config.modules config.drynix.nixos-configurations;
    flake.nixosConfigurations = mod.config.configurations config.drynix.nixos-configurations;
  };
}