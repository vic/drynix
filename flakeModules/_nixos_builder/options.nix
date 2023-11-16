top@{lib, config, ...}: 
arg@{builder, kind}: 
btm@{name, config, ...}: let 
  inherit (lib) mkOption types attrNames;

  kpath = top.config.drynix.lib.paths.${kind};

  inputs = if lib.pathExists (kpath.flake name) then 
      let
        flake = top.config.drynix.inputs.call-flake (kpath.base name);
        merge = flake.outputs.lib.mergeInputs or (x: x // flake.inputs);
      in merge top.config.drynix.inputs
    else top.config.drynix.inputs;

  builder = arg.builder btm;
in {
      options = {
        builder = mkOption {
          description = "Function used to create the nixos configuration.";
          inherit (builder.fn) default example;
        };

        hmModule = mkOption {
          description = ''
          home-manager's nixos module to include.

          NOTE: If you are using nixpkgs stable release, be sure to also use hm stable release.
          '';
          inherit (builder.hm) default example;
        };

        configuration = mkOption {
          description = "Main configuration module to load";
          default = top.config.drynix.lib.paths.${kind}.configuration name;
        };

        extraModules = mkOption {
          description = "Extra modules to load";
          inherit (builder.extraMods name) default example;
        };

        specialArgs = mkOption {
          description = "Special args for modules";
          default = {};
        };

        inputs = mkOption {
          description = "defaults to the system flake inputs if present.";
          default = inputs;
        };

        enableFeatures = mkOption {
          description = "features to enable from ${kind}Features.";
          default = [];
          type = types.listOf (types.enum (attrNames top.config.flake."${kind}Features"));
        };
      };
    }
