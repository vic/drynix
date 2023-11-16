top@{lib, config, ...}: let 
  inherit (lib) pipe id mapAttrs optional pathExists;
  inherit (config.drynix.lib) paths dirApply;

  detect = hp: pipe hp.path [
    (dirApply id)
    (mapAttrs (name: _: 
      {...}: {
        config._module.args.flakeConfig = config;
        imports = optional (pathExists (hp.default name)) (hp.default name);
      }
    ))
  ];

  drynix.nixos-configurations  = detect paths.nixos;
  drynix.darwin-configurations = detect paths.darwin;
  drynix.wsl-configurations    = detect paths.wsl;
  drynix.home-configurations   = detect paths.homes;

in {
  inherit drynix;
}
