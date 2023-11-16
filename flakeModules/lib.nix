top: { 
  options.drynix.lib = top.lib.mkOption {
    default = {
      dirApply = import ./_lib/dirApply.nix top;
      paths = import ./_lib/paths.nix top;
    };
    readOnly = true;
  };
}