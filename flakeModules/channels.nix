top@{lib, config, withSystem, ...}: let
  inherit (config.drynix.lib) dirApply;
  inherit (lib) mapAttrs types mkOption;

  getChannels = osArgs: sysArgs:
    mapAttrs (name: f: f osArgs sysArgs) config.drynix.channels;

in {
  options.drynix.channels = mkOption {
    description = "nixpkgs distributions";
    # {inputs,...}: {system, ...}: pkgsInstance
    type = types.lazyAttrsOf (types.functionTo (types.functionTo types.unspecified));
    default = dirApply (f: import f) "${config.drynix.self}/channels";
  };

  config.flake.nixosModules.channels = osArgs@{ config, inputs, ... }:
    let
      withSystem' = withSystem config.nixpkgs.hostPlatform.system;
      channels' = withSystem' (sysArgs@{system, ... }: getChannels osArgs sysArgs);
    in { _module.args = { inherit channels'; }; };
}