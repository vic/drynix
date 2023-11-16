top@{lib, config, ...}: let
  inherit (lib) mkOption types pipe listToAttrs mapAttrsToList mapAttrs flatten optional literalExample mkDefault length pathExists;
  inherit (config.drynix.lib) paths;


  mod = import ./_nixos_builder top {
    kind = "wsl";

    builder = {inputs, ...}: {
      fn = {
        default = config.inputs.nixpkgs.lib.nixosSystem;
        example = literalExample "inputs.nixpkgs.lib.nixosSystem";
      };
    
      hm = {
        default = config.inputs.home-manager.nixosModules.home-manager;
        example = literalExample "inputs.home-manager.nixosModules.home-manager";
      };

      extraMods = name: {
        default = [
          config.inputs.nixos-wsl.nixosModules.default
          { wsl.enable = true; }
        ]; 
        example = literalExample "[]";
      };
    };
  };


in {
  options.drynix.wsl-configurations = mod.options.configurations;
  config = {
    flake.wslModules = mod.config.modules config.drynix.wsl-configurations;
    flake.nixosConfigurations = mod.config.configurations config.drynix.wsl-configurations;
  };
}