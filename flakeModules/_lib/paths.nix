{ config, ...}: let 

  inherit (builtins) toPath;
  cfg = config.drynix;

  paths.homes = rec {
    path = toPath "${cfg.self}/homes";
    default = name: toPath "${path}/${name}/default.nix";
    configuration = name: toPath "${path}/${name}/homeConfiguration.nix";
    host = name: toPath "${path}/${name}/host.nix";
    user = name: toPath "${path}/${name}/user.nix";
  };

  osPath = kind: rec {
    path = toPath "${cfg.self}/${kind}";
    base = name: toPath "${path}/${name}";
    flake = name: toPath "${path}/${name}/flake.nix";
    default = name: toPath "${path}/${name}/default.nix";
    configuration = name: toPath "${path}/${name}/configuration.nix";
  };

  paths.nixos = osPath "nixos";
  paths.darwin = osPath "darwin";
  paths.wsl = osPath "wsl";
in paths
