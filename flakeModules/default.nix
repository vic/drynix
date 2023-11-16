top@{lib, ...}: let
  inherit (lib) pipe id attrValues;

  drynix-lib = (import ./lib.nix top).options.drynix.lib.default;
  inherit (drynix-lib) dirApply;

  flakeModules = pipe ./. [
     (dirApply id)
     (x: builtins.removeAttrs x ["default"])
  ];

in { imports = attrValues flakeModules; }
