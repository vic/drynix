top@{lib, config, ...}: {kind, builder}: let
  inherit (lib) mkOption types pipe listToAttrs mapAttrsToList mapAttrs flatten optional literalExample mkDefault length pathExists;
  inherit (config.drynix.lib) paths;

  flakeMods = config.flake."${kind}Modules";

  usersOnHost = hostName: pipe config.drynix.home-configurations [
    (mapAttrsToList (name: value: optional (value.hostName == hostName) { inherit name value; }))
    flatten
    listToAttrs
  ];

  mkHostModules = cfg: pipe cfg [
    (mapAttrsToList (hostName: cfg: {
      name = "host-${hostName}";
      value = mkHostModule hostName cfg;
    }))
    listToAttrs
  ];

  osHomeModule = homeName: homeCfg: [({config, lib, pkgs, ...}: let 
    # Default darwinHome. See https://github.com/LnL7/nix-darwin/issues/682
    darwinHomeModule = {
      config = lib.mkIf pkgs.stdenvNoCC.isDarwin {
         users.users.${homeCfg.userName}.home = lib.mkDefault "/Users/${homeCfg.userName}";
      };
    };
  in {
    imports = [ darwinHomeModule ];
    home-manager.users.${homeCfg.userName} = {osConfig, lib, pkgs, config, ...}: { 
      home.stateVersion = mkDefault osConfig.system.stateVersion;
      imports = [top.config.flake.homeModules.${homeName} ];
    };
  })];

  optionalIfExists = path: module: optional (pathExists path) module;
  osHostModule = homeName: homeCfg: optionalIfExists (paths.homes.host homeName) (paths.homes.host homeName);
  osUserModule = homeName: homeCfg: optionalIfExists (paths.homes.user homeName) (args@{lib, pkgs, config, ...}: {
    users.users.${homeCfg.userName} = args2@{...}: { 
      _module.args = args // args2;
      imports = [ (paths.homes.user homeName) ];
    };
  });

  homes = hostName: hostCfg: let 
    users = usersOnHost hostName;
    usersModules = pipe users [ 
      (mapAttrsToList (homeName: homeCfg: 
        (osHomeModule homeName homeCfg) ++
        (osUserModule homeName homeCfg) ++
        (osHostModule homeName homeCfg)
      )) 
      flatten
    ];

    module = {config, ...}: {
      home-manager.useUserPackages = lib.mkDefault true;
      home-manager.useGlobalPkgs = lib.mkDefault true;
      imports = [ hostCfg.hmModule ] ++ usersModules;
    };
  in optional (users != {}) module;

  features = hostName: hostCfg: let
    importFeature = name: _: {
      imports = [ top.config.flake."${kind}Features".${name} ];
      config.features.${name}.enable = lib.mkDefault true;
    };
  in map importFeature hostCfg.enableFeatures;

  baseModules = hostName: hostCfg: [
    top.config.flake.nixosModules.channels
    { _module.args.flakeConfig = top.config; }
  ];

  mkHostModule = hostName: hostCfg: {
    imports = (baseModules hostName hostCfg)++ hostCfg.extraModules ++
      (features hostName hostCfg) ++
      (optionalIfExists hostCfg.configuration hostCfg.configuration) ++
      (homes hostName hostCfg);
    options.features = {};
    config.networking.hostName = mkDefault hostName;
  };

  mkHostConfiguration = hostName: cfg: cfg.builder { 
    modules = [ flakeMods."host-${hostName}" ];
    specialArgs = cfg.specialArgs // { inputs = cfg.inputs; };
  };

in {
  options.configurations = mkOption {
    description = "NixOS configurations";
    default = {};
    type = types.lazyAttrsOf (types.submodule (import ./options.nix top { inherit builder kind; }));
  };

  config = {
    modules = mkHostModules;
    configurations = mapAttrs mkHostConfiguration;
  };
}
