top@{lib, config, ...}: let
  inherit (lib) mkOption types pipe listToAttrs mapAttrsToList mapAttrs flatten optional literalExample mkDefault length pathExists;
  inherit (config.drynix.lib) paths;


  mod = import ./_nixos_builder top {
    kind = "darwin";

    builder = {config, ...}: {
      fn = {
        default = config.inputs.nix-darwin.lib.darwinSystem;
        example = literalExample "inputs.nix-darwin.lib.darwinSystem";
      };
    
      hm = {
        default = config.inputs.home-manager.darwinModules.home-manager;
        example = literalExample "inputs.home-manager.darwinModules.home-manager";
      };

      extraMods = name: {
        default = []; 
        example = literalExample "[]";
      };
    };
  };


in {
  options.drynix.darwin-configurations = mod.options.configurations;
  config = {
    flake.darwinModules = mod.config.modules config.drynix.darwin-configurations;
    flake.darwinConfigurations = mod.config.configurations config.drynix.darwin-configurations;
  };
}
